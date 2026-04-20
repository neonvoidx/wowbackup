----------------------------------------------------------------------
-- MidnightCheatSheet – ItemDB.lua
-- Enchants, Gems, Consumables, and Spec database for Midnight S1.
-- Post-stat-squish values (ilvl 102-289 range, level 90 cap).
----------------------------------------------------------------------
local _, MCS = ...

----------------------------------------------------------------------
-- ENCHANTS (Midnight Season 1 crafted)
----------------------------------------------------------------------
MCS.EnchantDB = {
    -- Weapons
    { id = 244031, key = "ArcMastery",  slot = "Weapon",   name = "Arcane Mastery" },
    { id = 243973, key = "BerserkRage", slot = "Weapon",   name = "Berserker's Rage" },
    { id = 244029, key = "AcuityRen",   slot = "Weapon",   name = "Acuity of the Ren'dorei" },
    { id = 243971, key = "JanalaiPrec", slot = "Weapon",   name = "Janalai's Precision" },
    -- Rings
    { id = 244015, key = "SilvermoonAla", slot = "Ring",   name = "Silvermoon's Alacrity" },
    { id = 243959, key = "ZuljinMast",    slot = "Ring",   name = "Zul'jin's Mastery" },
    { id = 243987, key = "NatureFury",    slot = "Ring",   name = "Nature's Fury" },
    { id = 243957, key = "EyesEagle",     slot = "Ring",   name = "Eyes of the Eagle" },
    -- Chest
    { id = 243977, key = "MarkWorld",     slot = "Chest",  name = "Mark of the Worldsoul" },
    { id = 243947, key = "MarkNalo",      slot = "Chest",  name = "Mark of Nalorakk" },
    { id = 244003, key = "MarkMagister",  slot = "Chest",  name = "Mark of the Magister" },
    -- Helm
    { id = 244007, key = "RuneAvoid",    slot = "Helm",   name = "Empowered Rune of Avoidance" },
    { id = 243981, key = "BlessSpeed",   slot = "Helm",   name = "Empowered Blessing of Speed" },
    { id = 243951, key = "HexLeech",     slot = "Helm",   name = "Empowered Hex of Leech" },
    -- Shoulder
    { id = 243961, key = "FlightEagle",  slot = "Shoulder", name = "Flight of the Eagle" },
    { id = 243991, key = "AmirGrace",    slot = "Shoulder", name = "Amirdrassil's Grace" },
    { id = 243963, key = "AkilSwift",    slot = "Shoulder", name = "Akil'zon's Swiftness" },
    { id = 244021, key = "SilverMend",   slot = "Shoulder", name = "Silvermoon's Mending" },
    -- Boots
    { id = 243953, key = "LynxDex",      slot = "Boots",  name = "Lynx's Dexterity" },
    { id = 244009, key = "FarHunt",      slot = "Boots",  name = "Farseer's Hunt" },
    { id = 243983, key = "ShalRoots",    slot = "Boots",  name = "Shal'dorei's Roots" },
    -- Legs
    { id = 244641, key = "ForestKit",    slot = "Legs",   name = "Forest Hunter's Armor Kit" },
    { id = 240133, key = "SunfireThread", slot = "Legs",  name = "Sunfire Thread" },
    { id = 240155, key = "ArcThread",    slot = "Legs",   name = "Arcane Thread" },
    { id = 244643, key = "BloodKit",     slot = "Legs",   name = "Blood Knight's Armor Kit" },
    -- Runeforges (DK only, spell-based)
    { spellID = 53344,  key = "RuneFallenCrusader", slot = "Weapon", name = "Rune of the Fallen Crusader" },
    { spellID = 53343,  key = "RuneRazorice",       slot = "Weapon", name = "Rune of Razorice" },
    { spellID = 326805, key = "RuneSanguination",    slot = "Weapon", name = "Rune of Sanguination" },
    { spellID = 62158,  key = "RuneStoneskin",       slot = "Weapon", name = "Rune of the Stoneskin Gargoyle" },
    { spellID = 327082, key = "RuneApocalypse",      slot = "Weapon", name = "Rune of the Apocalypse" },
}
MCS.EnchantByKey = {}
for _, e in ipairs(MCS.EnchantDB) do MCS.EnchantByKey[e.key] = e end

----------------------------------------------------------------------
-- GEMS
----------------------------------------------------------------------
MCS.GemDB = {
    -- Epic (1 per character)
    { id = 240967, key = "Powerful",       quality = "Epic", name = "Powerful Eversong Diamond" },
    { id = 240983, key = "Indecipherable", quality = "Epic", name = "Indecipherable Eversong Diamond" },
    { id = 240969, key = "TelluricCrit",   quality = "Epic", name = "Telluric Eversong Diamond" },
    -- Rare (all other sockets)
    { id = 240892, key = "MastPeridot",    quality = "Rare", name = "Flawless Masterful Peridot" },
    { id = 240900, key = "QuickAmethyst",  quality = "Rare", name = "Flawless Quick Amethyst" },
    { id = 240898, key = "DeadlyAmethyst", quality = "Rare", name = "Flawless Deadly Amethyst" },
    { id = 240890, key = "DeadlyPeridot",  quality = "Rare", name = "Flawless Deadly Peridot" },
    { id = 240908, key = "MastGarnet",     quality = "Rare", name = "Flawless Masterful Garnet" },
    { id = 240914, key = "DeadlyLapis",    quality = "Rare", name = "Flawless Deadly Lapis" },
    { id = 240906, key = "QuickGarnet",    quality = "Rare", name = "Flawless Quick Garnet" },
    { id = 240918, key = "MastLapis",      quality = "Rare", name = "Flawless Masterful Lapis" },
    { id = 240916, key = "QuickLapis",     quality = "Rare", name = "Flawless Quick Lapis" },
    { id = 240894, key = "VersPeridot",    quality = "Rare", name = "Flawless Versatile Peridot" },
    { id = 240910, key = "VersGarnet",     quality = "Rare", name = "Flawless Versatile Garnet" },
}
MCS.GemByKey = {}
for _, g in ipairs(MCS.GemDB) do MCS.GemByKey[g.key] = g end

----------------------------------------------------------------------
-- CONSUMABLES
----------------------------------------------------------------------
MCS.ConsumDB = {
    -- Flasks
    { id = 241326, key = "FlaskSun",     cat = "Flask",   name = "Flask of the Shattered Sun" },
    { id = 241322, key = "FlaskMag",     cat = "Flask",   name = "Flask of the Magisters" },
    { id = 241324, key = "FlaskBK",      cat = "Flask",   name = "Flask of the Blood Knights" },
    { id = 245933, key = "FlaskMagFlee", cat = "Flask",   name = "Fleeting Flask of the Magisters" },
    { id = 241320, key = "FlaskResist",  cat = "Flask",   name = "Flask of the Resistance" },
    -- Food
    { id = 242272, key = "FoodQuel",       cat = "Food",  name = "Quel'dorei Medley" },
    { id = 255845, key = "FoodParade",     cat = "Food",  name = "Silvermoon Parade" },
    { id = 242747, key = "FoodRoast",      cat = "Food",  name = "Hearty Royal Roast" },
    { id = 255848, key = "FoodFrenzy",     cat = "Food",  name = "Flora Frenzy" },
    { id = 266996, key = "FoodHaranCel",   cat = "Food",  name = "Hearty Harandar Celebration" },
    { id = 242273, key = "FoodBloom",      cat = "Food",  name = "Silvermoon Bloom" },
    { id = 242275, key = "FoodRoyal",      cat = "Food",  name = "Royal Quel'dorei Feast" },
    { id = 242277, key = "FoodCalamari",   cat = "Food",  name = "Eversong Calamari" },
    { id = 242274, key = "FoodChamp",      cat = "Food",  name = "Champion's Bento" },
    { id = 255847, key = "FoodImpRoast",   cat = "Food",  name = "Imperial Roast" },
    { id = 267000, key = "FoodHeartyFlora", cat = "Food", name = "Hearty Flora Feast" },
    { id = 266985, key = "FoodHeartyParade", cat = "Food", name = "Hearty Silvermoon Parade" },
    -- Potions
    { id = 241288, key = "PotReck",      cat = "Potion",  name = "Potion of Recklessness" },
    { id = 241308, key = "PotLight",     cat = "Potion",  name = "Light's Potential" },
    { id = 241292, key = "PotRampant",   cat = "Potion",  name = "Draught of Rampant Abandon" },
    -- Healing / Mana
    { id = 241304, key = "HealHP",       cat = "Healing", name = "Silvermoon Health Potion" },
    { id = 241300, key = "HealMana",     cat = "Mana",    name = "Lightfused Mana Potion" },
    -- Rune
    { id = 259085, key = "AugRune",      cat = "Rune",    name = "Void-Touched Augment Rune" },
    -- Weapon enhancements (temp)
    { id = 243734, key = "OilPhoenix",   cat = "Oil",     name = "Thalassian Phoenix Oil" },
}
MCS.ConsumByKey = {}
for _, c in ipairs(MCS.ConsumDB) do MCS.ConsumByKey[c.key] = c end

----------------------------------------------------------------------
-- SPEC DATABASE
-- Post-stat-squish Midnight Season 1 values.
-- Breakpoint ratings are for ilvl ~250 (Champion 6) at level 90.
-- After squish: ~33 rating = 1% secondary stat at level 90.
-- weights: relative to primary stat = 1.00
-- breakpoints: { stat, pct (target %), rating (approx), note }
----------------------------------------------------------------------
MCS.SpecDB = {}
local D = MCS.SpecDB

local function S(stats, enchants, rings, gems, consum)
    return { stats=stats, enchants=enchants, rings=rings, gems=gems, consum=consum }
end

----------------------------------------------------------------------
-- All 40 specs - hero-tree stat priorities
-- stats = { ["HeroTree1"] = {"Stat","Stat",...}, ["HeroTree2"] = {...} }
----------------------------------------------------------------------

-- DEATH KNIGHT
D["DEATHKNIGHT_BLOOD"] = S(
    { ["Deathbringer"] = {"Crit","Mastery","Vers","Haste"},
      ["San'layn"] = {"Haste","Mastery","Crit","Vers"} },
    { runeforge={
        {key="RuneSanguination", label="San'layn / Deathbringer ST"},
        {key="RuneFallenCrusader", label="Deathbringer AoE"},
      }, chest="MarkWorld", helm="BlessSpeed", shoulder="AkilSwift", boots="FarHunt", legs="ForestKit" },
    {"NatureFury"},
    { epic="Indecipherable", rare={"QuickGarnet","MastGarnet"} },
    { Flask="FlaskBK", Food="FoodBloom", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["DEATHKNIGHT_FROST"] = S(
    { ["Deathbringer"] = {"Crit","Mastery","Haste","Vers"},
      ["Rider of the Apocalypse"] = {"Crit","Mastery","Haste","Vers"} },
    { runeforge={
        {key="RuneRazorice", label="Shattering Blade MH"},
        {key="RuneFallenCrusader", label="All builds OH / 2H"},
        {key="RuneStoneskin", label="Non-Shattering Blade MH"},
      }, chest="MarkWorld", helm="BlessSpeed", shoulder="AkilSwift", boots="FarHunt", legs="ForestKit" },
    {"EyesEagle"},
    { epic="Indecipherable", rare={"MastGarnet","DeadlyAmethyst","DeadlyPeridot","DeadlyLapis"} },
    { Flask="FlaskSun", Food="FoodRoyal", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["DEATHKNIGHT_UNHOLY"] = S(
    { ["Rider of the Apocalypse"] = {"Mastery","Crit","Haste","Vers"},
      ["San'layn"] = {"Mastery","Crit","Haste","Vers"} },
    { runeforge={
        {key="RuneApocalypse", label="All builds"},
      }, chest="MarkWorld", helm="BlessSpeed", shoulder="FlightEagle", boots="FarHunt", legs="ForestKit" },
    {"ZuljinMast"},
    { epic="Indecipherable", rare={"MastGarnet","DeadlyAmethyst"} },
    { Flask="FlaskSun", Food="FoodParade", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- DEMON HUNTER
D["DEMONHUNTER_HAVOC"] = S(
    { ["Aldrachi Reaver"] = {"Crit","Mastery","Haste","Vers"},
      ["Fel-Scarred"] = {"Crit","Mastery","Haste","Vers"} },
    { wep={"AcuityRen","JanalaiPrec","ArcMastery"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="ForestKit" },
    {"EyesEagle"},
    { epic="Indecipherable", rare={"MastGarnet"} },
    { Flask="FlaskSun", Food="FoodRoyal", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["DEMONHUNTER_VENGEANCE"] = S(
    { ["Aldrachi Reaver"] = {"Haste","Crit","Vers","Mastery"},
      ["Annihilator"] = {"Haste","Crit","Vers","Mastery"} },
    { wep={"AcuityRen","BerserkRage","JanalaiPrec","ArcMastery"}, chest="MarkWorld", helm="BlessSpeed", shoulder="AkilSwift", boots="FarHunt", legs="ForestKit" },
    {"EyesEagle","SilvermoonAla"},
    { epic="Indecipherable", rare={"DeadlyPeridot","VersPeridot","QuickLapis","QuickGarnet","QuickAmethyst"} },
    { Flask="FlaskBK", Food="FoodBloom", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["DEMONHUNTER_DEVOURER"] = S(
    { ["Annihilator"] = {"Haste","Mastery","Crit","Vers"},
      ["Void-Scarred"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"ArcMastery","BerserkRage","AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="SunfireThread" },
    {"ZuljinMast","SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickAmethyst"} },
    { Flask="FlaskMag", Food="FoodParade", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- DRUID
D["DRUID_BALANCE"] = S(
    { ["Keeper of the Grove"] = {"Mastery","Haste","Crit","Vers"},
      ["Elune's Chosen"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="SunfireThread" },
    {"ZuljinMast"},
    { epic="Indecipherable", rare={"QuickAmethyst","MastGarnet","MastPeridot","MastLapis"} },
    { Flask="FlaskMag", Food="FoodBloom", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["DRUID_FERAL"] = S(
    { ["Druid of the Claw"] = {"Mastery","Haste","Crit","Vers"},
      ["Wildstalker"] = {"Mastery","Crit","Haste","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="ForestKit" },
    {"ZuljinMast"},
    { epic="Powerful", rare={"QuickAmethyst","MastGarnet","MastLapis"} },
    { Flask="FlaskSun", Food="FoodRoyal", Potion="PotRampant", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["DRUID_GUARDIAN"] = S(
    { ["Druid of the Claw"] = {"Haste","Vers","Crit","Mastery"},
      ["Elune's Chosen"] = {"Haste","Vers","Crit","Mastery"} },
    { wep={"BerserkRage"}, chest="MarkWorld", helm="BlessSpeed", shoulder="AkilSwift", boots="FarHunt", legs="ForestKit" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"VersPeridot"} },
    { Flask="FlaskBK", Food="FoodParade", Potion="PotRampant", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["DRUID_RESTORATION"] = S(
    { ["Keeper of the Grove"] = {"Haste","Mastery","Vers","Crit"},
      ["Wildstalker"] = {"Haste","Mastery","Vers","Crit"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="ArcThread" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickAmethyst","MastPeridot"} },
    { Flask="FlaskBK", Food="FoodRoyal", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix", Mana="HealMana" })
-- EVOKER
D["EVOKER_DEVASTATION"] = S(
    { ["Flameshaper"] = {"Crit","Haste","Mastery","Vers"},
      ["Scalecommander"] = {"Crit","Haste","Mastery","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="SunfireThread" },
    {"NatureFury"},
    { epic="Indecipherable", rare={"QuickGarnet","MastGarnet","DeadlyPeridot","DeadlyAmethyst","DeadlyLapis"} },
    { Flask="FlaskSun", Food="FoodQuel", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["EVOKER_PRESERVATION"] = S(
    { ["Flameshaper"] = {"Mastery","Haste","Crit","Vers"},
      ["Chronowarden"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="ArcThread" },
    {"ZuljinMast"},
    { epic="Indecipherable", rare={"QuickAmethyst"} },
    { Flask="FlaskMag", Food="FoodRoyal", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix", Mana="HealMana" })
D["EVOKER_AUGMENTATION"] = S(
    { ["Chronowarden"] = {"Crit","Haste","Mastery","Vers"},
      ["Scalecommander"] = {"Crit","Haste","Mastery","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="SunfireThread" },
    {"NatureFury"},
    { epic="Indecipherable", rare={"QuickGarnet"} },
    { Flask="FlaskSun", Food="FoodHeartyParade", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- HUNTER
D["HUNTER_BEAST_MASTERY"] = S(
    { ["Pack Leader"] = {"Mastery","Haste","Crit","Vers"},
      ["Dark Ranger"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="ForestKit" },
    {"ZuljinMast"},
    { epic="Indecipherable", rare={"QuickAmethyst","DeadlyAmethyst","MastPeridot"} },
    { Flask="FlaskMag", Food="FoodQuel", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["HUNTER_MARKSMANSHIP"] = S(
    { ["Sentinel"] = {"Crit","Mastery","Vers","Haste"},
      ["Dark Ranger"] = {"Crit","Mastery","Vers","Haste"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="ForestKit" },
    {"EyesEagle"},
    { epic="Powerful", rare={"DeadlyPeridot","DeadlyAmethyst","DeadlyLapis","MastGarnet"} },
    { Flask="FlaskSun", Food="FoodHaranCel", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["HUNTER_SURVIVAL"] = S(
    { ["Pack Leader"] = {"Mastery","Crit","Haste","Vers"},
      ["Sentinel"] = {"Mastery","Crit","Haste","Vers"} },
    { wep={"ArcMastery","AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="ForestKit" },
    {"ZuljinMast"},
    { epic="Indecipherable", rare={"DeadlyAmethyst"} },
    { Flask="FlaskMagFlee", Food="FoodParade", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- MAGE
D["MAGE_ARCANE"] = S(
    { ["Spellslinger"] = {"Mastery","Haste","Crit","Vers"},
      ["Sunfury"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="SilverMend", boots="ShalRoots", legs="ArcThread" },
    {"EyesEagle"},
    { epic="Powerful", rare={"QuickAmethyst","MastPeridot","MastGarnet","MastLapis"} },
    { Flask="FlaskResist", Food="FoodParade", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["MAGE_FIRE"] = S(
    { ["Frostfire"] = {"Haste","Mastery","Vers","Crit"},
      ["Sunfury"] = {"Haste","Mastery","Vers","Crit"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="SunfireThread" },
    {"EyesEagle"},
    { epic="Powerful", rare={"MastPeridot","QuickAmethyst","QuickLapis","QuickGarnet"} },
    { Flask="FlaskMag", Food="FoodQuel", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["MAGE_FROST"] = S(
    { ["Frostfire"] = {"Mastery","Crit","Haste","Vers"},
      ["Spellslinger"] = {"Mastery","Crit","Haste","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="SunfireThread" },
    {"ZuljinMast"},
    { epic="Powerful", rare={"DeadlyAmethyst","MastGarnet","MastPeridot","MastLapis"} },
    { Flask="FlaskMag", Food="FoodChamp", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- MONK
D["MONK_BREWMASTER"] = S(
    { ["Defensive"] = {"Vers","Crit","Mastery","Haste"},
      ["Offensive"] = {"Crit","Mastery","Vers","Haste"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="ForestKit" },
    {"NatureFury"},
    { epic="Indecipherable", rare={"VersGarnet","DeadlyLapis","DeadlyAmethyst","VersPeridot"} },
    { Flask="FlaskSun", Food="FoodParade", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["MONK_MISTWEAVER"] = S(
    { ["Raid"] = {"Haste","Crit","Vers","Mastery"},
      ["Mythic+"] = {"Haste","Crit","Vers","Mastery"} },
    { wep={"AcuityRen","BerserkRage"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="SunfireThread" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"DeadlyPeridot"} },
    { Flask="FlaskBK", Food="FoodHaranCel", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix", Mana="HealMana" })
D["MONK_WINDWALKER"] = S(
    { ["Shado-Pan"] = {"Haste","Crit","Mastery","Vers"},
      ["Conduit of the Celestials"] = {"Haste","Mastery","Crit","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="ForestKit" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"DeadlyPeridot","QuickAmethyst","QuickGarnet"} },
    { Flask="FlaskBK", Food="FoodParade", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- PALADIN
D["PALADIN_HOLY"] = S(
    { ["Herald of the Sun"] = {"Mastery","Haste","Crit","Vers"},
      ["Lightsmith"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"AcuityRen"}, chest="MarkMagister", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="ArcThread" },
    {"ZuljinMast"},
    { epic="TelluricCrit", rare={"QuickAmethyst","MastGarnet","MastPeridot","MastLapis"} },
    { Flask="FlaskMag", Food="FoodRoast", Potion="PotReck", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix", Mana="HealMana" })
D["PALADIN_PROTECTION"] = S(
    { ["Survivability"] = {"Haste","Vers","Mastery","Crit"},
      ["DPS"] = {"Haste","Vers","Crit","Mastery"} },
    { wep={"BerserkRage"}, chest="MarkWorld", helm="BlessSpeed", shoulder="AkilSwift", boots="FarHunt", legs="ForestKit" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"VersPeridot"} },
    { Flask="FlaskBK", Food="FoodParade", Potion="PotRampant", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["PALADIN_RETRIBUTION"] = S(
    { ["Templar"] = {"Mastery","Crit","Haste","Vers"},
      ["Herald of the Sun"] = {"Mastery","Crit","Haste","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="BlessSpeed", shoulder="AkilSwift", boots="FarHunt", legs="ForestKit" },
    {"EyesEagle"},
    { epic="Indecipherable", rare={"DeadlyAmethyst","MastGarnet"} },
    { Flask="FlaskMag", Food="FoodRoyal", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- PRIEST
D["PRIEST_DISCIPLINE"] = S(
    { ["Oracle"] = {"Haste","Crit","Mastery","Vers"},
      ["Voidweaver"] = {"Haste","Crit","Mastery","Vers"} },
    { wep={"BerserkRage"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="SunfireThread" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"DeadlyPeridot"} },
    { Flask="FlaskBK", Food="FoodRoyal", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix", Mana="HealMana" })
D["PRIEST_HOLY"] = S(
    { ["Archon"] = {"Crit","Vers","Mastery","Haste"},
      ["Oracle"] = {"Crit","Vers","Mastery","Haste"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="SunfireThread" },
    {"NatureFury"},
    { epic="Indecipherable", rare={"VersGarnet"} },
    { Flask="FlaskSun", Food="FoodRoyal", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix", Mana="HealMana" })
D["PRIEST_SHADOW"] = S(
    { ["Archon"] = {"Haste","Mastery","Crit","Vers"},
      ["Voidweaver"] = {"Haste","Mastery","Crit","Vers"} },
    { wep={"ArcMastery"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AkilSwift", boots="LynxDex", legs="SunfireThread" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickGarnet","DeadlyAmethyst","MastPeridot"} },
    { Flask="FlaskBK", Food="FoodBloom", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- ROGUE
D["ROGUE_ASSASSINATION"] = S(
    { ["Deathstalker"] = {"Crit","Haste","Mastery","Vers"},
      ["Fatebound"] = {"Crit","Haste","Mastery","Vers"} },
    { wep={"BerserkRage"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="ForestKit" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickGarnet"} },
    { Flask="FlaskSun", Food="FoodParade", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["ROGUE_OUTLAW"] = S(
    { ["Fatebound"] = {"Haste","Crit","Vers","Mastery"},
      ["Trickster"] = {"Haste","Crit","Vers","Mastery"} },
    { wep={"JanalaiPrec","AcuityRen"}, chest="MarkWorld", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="ForestKit" },
    {"EyesEagle","SilvermoonAla"},
    { epic="Indecipherable", rare={"DeadlyPeridot","VersGarnet","DeadlyAmethyst","QuickGarnet","QuickLapis"} },
    { Flask="FlaskSun", Food="FoodRoast", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["ROGUE_SUBTLETY"] = S(
    { ["Deathstalker"] = {"Mastery","Haste","Crit","Vers"},
      ["Trickster"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"AcuityRen","ArcMastery","BerserkRage","JanalaiPrec"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="ForestKit" },
    {"EyesEagle"},
    { epic="Indecipherable", rare={"QuickAmethyst","DeadlyPeridot","MastGarnet"} },
    { Flask="FlaskMag", Food="FoodParade", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- SHAMAN
D["SHAMAN_ELEMENTAL"] = S(
    { ["Stormbringer"] = {"Mastery","Haste","Crit","Vers"},
      ["Farseer"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"ArcMastery","JanalaiPrec"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="SunfireThread" },
    {"ZuljinMast"},
    { epic="Powerful", rare={"MastGarnet","MastPeridot","DeadlyAmethyst","MastLapis"} },
    { Flask="FlaskMag", Food="FoodHaranCel", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["SHAMAN_ENHANCEMENT"] = S(
    { ["Stormbringer"] = {"Haste","Mastery","Crit","Vers"},
      ["Totemic"] = {"Mastery","Haste","Crit","Vers"} },
    { wep={"AcuityRen"}, chest="MarkWorld", helm="RuneAvoid", shoulder="AmirGrace", boots="LynxDex", legs="ForestKit" },
    {"ZuljinMast"},
    { epic="Indecipherable", rare={"QuickAmethyst","MastPeridot"} },
    { Flask="FlaskMag", Food="FoodParade", Potion="PotLight", Healing="HealHP", Rune="AugRune" })
D["SHAMAN_RESTORATION"] = S(
    { ["Farseer"] = {"Crit","Mastery","Vers","Haste"},
      ["Totemic"] = {"Crit","Mastery","Vers","Haste"} },
    { wep={"AcuityRen"}, chest="MarkMagister", helm="HexLeech", shoulder="SilverMend", boots="ShalRoots", legs="ArcThread" },
    {"NatureFury"},
    { epic="Indecipherable", rare={"VersGarnet","DeadlyPeridot","DeadlyLapis","DeadlyAmethyst"} },
    { Flask="FlaskSun", Food="FoodParade", Potion="PotReck", Healing="HealHP", Rune="AugRune", Mana="HealMana" })
-- WARLOCK
D["WARLOCK_AFFLICTION"] = S(
    { ["Hellcaller"] = {"Mastery","Crit","Haste","Vers"},
      ["Soul Harvester"] = {"Mastery","Crit","Haste","Vers"} },
    { wep={"JanalaiPrec"}, chest="MarkWorld", helm="RuneAvoid", shoulder="FlightEagle", boots="LynxDex", legs="SunfireThread" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickGarnet","DeadlyAmethyst","MastPeridot"} },
    { Flask="FlaskMag", Food="FoodRoyal", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["WARLOCK_DEMONOLOGY"] = S(
    { ["Diabolist"] = {"Haste","Crit","Mastery","Vers"},
      ["Soul Harvester"] = {"Haste","Crit","Mastery","Vers"} },
    { wep={"JanalaiPrec"}, chest="MarkWorld", helm="RuneAvoid", shoulder="FlightEagle", boots="LynxDex", legs="SunfireThread" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickGarnet","DeadlyAmethyst","MastPeridot"} },
    { Flask="FlaskSun", Food="FoodRoyal", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["WARLOCK_DESTRUCTION"] = S(
    { ["Diabolist"] = {"Haste","Mastery","Crit","Vers"},
      ["Hellcaller"] = {"Haste","Mastery","Crit","Vers"} },
    { wep={"JanalaiPrec"}, chest="MarkWorld", helm="RuneAvoid", shoulder="FlightEagle", boots="LynxDex", legs="SunfireThread" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickGarnet","DeadlyAmethyst","MastPeridot"} },
    { Flask="FlaskMag", Food="FoodRoyal", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
-- WARRIOR
D["WARRIOR_ARMS"] = S(
    { ["Colossus"] = {"Crit","Haste","Mastery","Vers"},
      ["Slayer"] = {"Crit","Haste","Mastery","Vers"} },
    { wep={"AcuityRen","BerserkRage"}, chest="MarkWorld", helm="HexLeech", shoulder="AmirGrace", boots="LynxDex", legs="BloodKit" },
    {"NatureFury","SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickGarnet","DeadlyPeridot"} },
    { Flask="FlaskSun", Food="FoodBloom", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["WARRIOR_FURY"] = S(
    { ["Mountain Thane"] = {"Haste","Mastery","Crit","Vers"},
      ["Slayer"] = {"Haste","Mastery","Crit","Vers"} },
    { wep={"ArcMastery","BerserkRage"}, chest="MarkWorld", helm="HexLeech", shoulder="AmirGrace", boots="LynxDex", legs="BloodKit" },
    {"ZuljinMast","SilvermoonAla"},
    { epic="Indecipherable", rare={"QuickAmethyst","MastPeridot"} },
    { Flask="FlaskMag", Food="FoodBloom", Potion="PotLight", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
D["WARRIOR_PROTECTION"] = S(
    { ["Colossus"] = {"Haste","Crit","Vers","Mastery"},
      ["Mountain Thane"] = {"Haste","Crit","Vers","Mastery"} },
    { wep={"BerserkRage"}, chest="MarkWorld", helm="BlessSpeed", shoulder="AkilSwift", boots="FarHunt", legs="ForestKit" },
    {"SilvermoonAla"},
    { epic="Indecipherable", rare={"VersPeridot"} },
    { Flask="FlaskBK", Food="FoodParade", Potion="PotRampant", Healing="HealHP", Rune="AugRune", Oil="OilPhoenix" })
----------------------------------------------------------------------
-- TALENT BUILDS (export strings per spec per content type)
----------------------------------------------------------------------
MCS.TalentDB = {
    ["DEATHKNIGHT_BLOOD"] = {
        ["M+"] = "CoPAAAAAAAAAAAAAAAAAAAAAAwMzyMzMmxMzMMLzMz0MLGjxMGAAAAwMmZmZmZYGjBAjZmZGAAAjZbgBsEsNMBGWAMjZAAYmBwgB",
        ["Raid ST"] = "CoPAAAAAAAAAAAAAAAAAAAAAAwYWGzMmxMjhZZmZmmZxYmxMmBAAAAzMzMzMzMDzYMAgZmZGAAAGYgZspxyGILDYDwMMDAAMzADGA",
    },
    ["DEATHKNIGHT_FROST"] = {
        ["M+"] = "CsPAAAAAAAAAAAAAAAAAAAAAAMAzMjZmZAz2MzMzMLmZkZMmZmZGYMzwMzMjZAAAAAAAAAwY2GYALglhJkxCmZYmBmBwwMDwMgB",
        ["Raid ST"] = "CsPAAAAAAAAAAAAAAAAAAAAAAMDwMjZMDY2mZmZmZZmZkZMmZYGGPgZGMzMzMDAAAAAAAAAGz2ADYBsMMhMWwMjZmBmBwwMDwMDM",
    },
    ["DEATHKNIGHT_UNHOLY"] = {
        ["M+"] = "CwPAAAAAAAAAAAAAAAAAAAAAAAYmZMjZMDz2MzMTDzMmZGDAAAAAAAAz8AMzAglZMzsNzMGGgFzmhhMwsxQjFMgZAYMzMmBYmZYGD",
    },
    ["DEMONHUNTER_HAVOC"] = {
        ["M+"] = "CEkAAAAAAAAAAAAAAAAAAAAAAYmZmZmZ2mxMzMGzkxMDAAAAAAYWMmtZYmBmx2sNzMjxALDsNbmxwsopxMzYGbAAAADAAAgZGMAAAAM",
        ["Raid ST"] = "CEkAAAAAAAAAAAAAAAAAAAAAAYGMzMzmxMzMmZmMmZAAAAAAAzyDMmtZYmZ2mZGbz28AzwYYsMw2sYGDzmmGzMjhNAAAAAAAAmZwAAAAwA",
    },
    ["DEMONHUNTER_VENGEANCE"] = {
        ["M+"] = "CUkAAAAAAAAAAAAAAAAAAAAAAAAYMzMjhZkZmBWMjZwMjZGz8AzMzYYmtZGbjZMGzAAAAAAAIgZmxGAAAAGYmZmZWabmZGAMDAAAgB",
        ["Raid ST"] = "CUkAAAAAAAAAAAAAAAAAAAAAAAAYMzMjZmZkZmZYYmZGDzYmxMmxMmxMmZsNzMGDAAAAAAAEwMzYDAAAADGzMzMLtNzMDAMAAAAG",
    },
    ["DEMONHUNTER_DEVOURER"] = {
        ["M+"] = "CgcBAAAAAAAAAAAAAAAAAAAAAAA2mxMzMzMzMGmBAAAAAAgxsNYGAAAAAAAAmxMMmZmZmZmZGzsYGjFtsxMzMzWLzMzAYYAIwMGMmB",
        ["Raid ST"] = "CgcBAAAAAAAAAAAAAAAAAAAAAAA2MmZmxMzMGzMAAAAAAAegxsNYGAAAAAAAAmxMMmZmZmZmZGzsYGjFtsxMzMzWbzMzAYYAIwMGMmB",
    },
    ["DRUID_BALANCE"] = {
        ["M+"] = "CYGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWoMbNMmZgxsMzMzMLMgZZmlZWMzMWYZmlxMjxGGAMW2mZwY2GBmAAAAswMzMD2MmxYAAYmBGA",
        ["Raid ST"] = "CYGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWoMbNjxMDMmlZmZmBYYWmZbYGzYjlZMzMjZ2wAgBYZbshpZmlRAAAA2MzMzMYzYYMDgZGAYA",
    },
    ["DRUID_FERAL"] = {
        ["M+"] = "CcGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAmZYmZmZMzsZsNz2MzMzDMzAAAAwSwsYMMzomxsYmZmZZMzAAAAAAgBAAAAoZWmtZmZABWAzMALMYAAAMzGG",
        ["Raid ST"] = "CcGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAjZwMzMzMmtlxyMbzYGzMDAAAALBzihxMjaGziZmZGjZYAAAAAAMwAAAAIAY2mZpZbmlNwMDwiZwAAYmBAD",
    },
    ["DRUID_GUARDIAN"] = {
        ["M+"] = "CgGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgZmZmlhZMziZZMzMWGY2MMaimZmlZmZmZZMDAAAAAAzYZGwy2MDGzyAYKAAAwmxMPAwiZwAWwAMzAYA",
        ["Raid ST"] = "CgGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgZmxsMPwYM2MLzMPgZZZgZDGNRzMzyMzMzYMjZAAAAAADLzAAAAQNzysMzMDAgFMzAsYGMYwy2AgZWgB",
    },
    ["DRUID_RESTORATION"] = {
        ["M+"] = "CkGAAAAAAAAAAAAAAAAAAAAAAMMmZZMjZmxsN8AMzsMjFbzAAAAAAAAAAglBNbGmmhZMmFzMzMLGegZAAAAAAAwAAQAAAz2MbNbzsYjxMDMzCoZAAmZAYA",
        ["Raid ST"] = "CkGAAAAAAAAAAAAAAAAAAAAAAMjxMbz2MmZGzywDMmxmxCzAAAAAAAAAAgtBNbMmmhxMmlZmZmhhZGAAAAAAAAstNWw0MzyAAAEwCjZGMzA0MAYmBAMA",
    },
    ["EVOKER_AUGMENTATION"] = {
        ["M+"] = "CEcBAAAAAAAAAAAAAAAAAAAAAMmZmZbmZmxyAzsMjxwMAAAAAAAAYmBmBjHoGzMzAAAAgZmZmxMz2YmBmZzYwCsMGGbDgZiYDzMDmZAM",
        ["Raid ST"] = "CEcBAAAAAAAAAAAAAAAAAAAAAMmZmZbmZmxyAzsMjxwMAAAAAgBAAzMDMYM1YmZGAAAAMjZmxMzyYmBmZzYwCsMGGbDgZiYDzMwMDgB",
    },
    ["EVOKER_DEVASTATION"] = {
        ["M+"] = "CsbBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzMDgZGmBGGjZaMzMNDz2MmZmZmZmZGwMzMGzMLzMDMwYwCsMGN2GQmBBbYGMzghB",
        ["Raid ST"] = "CsbBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzMDMDzYmBMYMTzMzMNjx2MmZmZmHYmZGwMmxYmZZmZgBGDWglxox2AyMIYDDMzghB",
    },
    ["EVOKER_PRESERVATION"] = {
        ["M+"] = "CwbBAAAAAAAAAAAAAAAAAAAAAAAAAAAMzMz2yADzMmFzYM2mxAAAzYmZmZMMTMmBAAA2mZmJjZmZGjZAAYMjNWgBmRDNMsAzMzAwA",
        ["Raid ST"] = "CwbBAAAAAAAAAAAAAAAAAAAAAAAAAAAYmZ2WmHADzMmFjZmZWmxAAAzYGDmxMyMzAAAAMzMTmxMjZbmZAwAjZsxCMwMaoBsAjZGgxA",
    },
    ["HUNTER_BEAST_MASTERY"] = {
        ["M+"] = "C0PAAAAAAAAAAAAAAAAAAAAAAYzsNwAGwMsBZsAAgZGLzMDzwMzMYGzMzwMmZGzMzYbmZYMDLDNDAAAAAYGAAAmHYMzwMDQAzCYzA",
        ["Raid ST"] = "C0PAAAAAAAAAAAAAAAAAAAAAAAMmxwCsAzwQDbAAYG2GzsNzwMmZYYmxYmxMzYGzwMzYGzghmBAAAAAMDAAAzMzMAzshwwsA2MA",
    },
    ["HUNTER_MARKSMANSHIP"] = {
        ["M+"] = "C4PAAAAAAAAAAAAAAAAAAAAAAwCMwMGNWGAzgNAAAAAAAAgZMzMjtZMzMmhlx0MGjZ222MzMDzMsMzsMGzywMDAAgxYAYmpNGGgNM",
        ["Raid ST"] = "C4PAAAAAAAAAAAAAAAAAAAAAAwCMwMGNWGAzgNAAAAAAAAgZMjZYGzMjZwYaGjZmZbbzMzMMzgZmlxYWGMDAAYMzMDAzMttBDw2wA",
    },
    ["HUNTER_SURVIVAL"] = {
        ["M+"] = "C8PAAAAAAAAAAAAAAAAAAAAAAMgxMG2ILwMM0gFzMzMzwyAAAAAAgZMzMDzYYMDGTzAAAAAGAALLzMziZmZmZGzMgZ2AgxYmZhB",
        ["Raid ST"] = "C8PAAAAAAAAAAAAAAAAAAAAAAMgxMG2ILwMM0gFjZmZmxyAAAAAAgZMzMDzYYMDGTzAAAAAAAYZZmZWMzMzMzYMgZ2AMLGjZmNG",
    },
    ["MAGE_ARCANE"] = {
        ["M+"] = "C4DAAAAAAAAAAAAAAAAAAAAAAMzwYZmZmFmZGamxAAAwAAgAmZmZZZmJWAAYbYmZMbLWmZmxMjxYmZmxCzMzYGAgBAAwMLAgZAwwA",
        ["Raid ST"] = "C4DAAAAAAAAAAAAAAAAAAAAAAYGGLzMzswMzQzMzAAAwAAgAmZmZZZmZYBAgtxMzMmtFLzMzYmxYMzMGLMzMjZAAGAAAzsAAmBADD",
    },
    ["MAGE_FIRE"] = {
        ["M+"] = "C8DAAAAAAAAAAAAAAAAAAAAAAMzwMLzMzsgZGZmxAAAwAAmZmmlltZAA2MzM2GzMzYDAAAAAWMzMzMAAYMDjZmZmZbAYmhwYMYGG",
        ["Raid ST"] = "C8DAAAAAAAAAAAAAAAAAAAAAAYGGLzMzswMDZmZGAAAGAwMz0sssMDAwmZmx2YmZGAAAAAgFzMzMDAAGzwYmZmZ2GAmZIjxYwMMA",
    },
    ["MAGE_FROST"] = {
        ["M+"] = "CAEAAAAAAAAAAAAAAAAAAAAAAMzwYZmZmFmZmYGmZmZmZWMzMMjZAAAgZmZWWmZaDAAWAAAAWAYbbMzMDmthxMjNAAAmZDYmMGwMYA",
        ["Raid ST"] = "CAEAAAAAAAAAAAAAAAAAAAAAAYGGLzMzsMmZmYmxMjZMziZmZmZMDAAAMzMzyyMTbAAAAAAgNA22GzMzgZZeAjZYBAAgZWAmJjBMDGA",
    },
    ["MONK_BREWMASTER"] = {
        ["M+"] = "CwQAAAAAAAAAAAAAAAAAAAAAAAAAAwMLbGDzwyM2MmZAAAAAAAYZBmYmBmhBzgZmZGzsNMjZWGW2ssNbzYWAAgNEAAgZbWamZmNG2AYmhpxAGAwA",
        ["Raid ST"] = "CwQAAAAAAAAAAAAAAAAAAAAAAAAAAgZbzYGPwYWM2mxMDAAAAAAALLYEmBmhxmZMmZmZMzywMmZZYZzy2sMMLAAwysMtMbzsMAAQAmhNwMDYaMAAgB",
    },
    ["MONK_MISTWEAVER"] = {
        ["M+"] = "C4QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMWmZZYxmxMjNstsNjZYmttlZGLMjmxMgBDGzyMzMDzGmhZZmAAAAAIAL2mZZ2mZAAAgBYGwYgFZMDA",
        ["Raid ST"] = "C4QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAghx2MwmFzYmZZGbYmZYmlttZGLMjmxMgBDGzyMzMDz2gBLmAAAAAIALWmZZ2mZAAgBMAzAGDjFZMDA",
    },
    ["MONK_WINDWALKER"] = {
        ["M+"] = "C0QAAAAAAAAAAAAAAAAAAAAAAMzYMghZZmZ2mxAAAAAAAAAAAALDzEmhhBMjhZmZGmthZYWmJAgNzsNGGzMDAgNAYWmlmZmZBYYgZGAYZMEDYA",
        ["Raid ST"] = "C0QAAAAAAAAAAAAAAAAAAAAAAMzYw2wwsMzMbzAAAAAAAAAAAAsMMCzYbYAzYYmZmhZZYGmlZCAYzMbzMMmZGAAbAwsMLNzMzCAGYmBAWGDxAG",
    },
    ["PALADIN_HOLY"] = {
        ["M+"] = "CEEAAAAAAAAAAAAAAAAAAAAAAAAAAYBAMDAwglxMzMzYmZWgxwyYbmZxMNxwYmZYY2yAwAwGYjlZmZWmtZmZrBAAAYhNMDbGYGzAAAmZYGjRD",
        ["Raid ST"] = "CEEAAAAAAAAAAAAAAAAAAAAAAAAAAYBAMAAglZmZGzYmZ2YMGzyYbmZxoJGzYmZYY2yAwAG2AbsMjZWmtZmZrBAAAYBA2MMmxMAAgZGmxY0A",
    },
    ["PALADIN_PROTECTION"] = {
        ["M+"] = "CIEAAAAAAAAAAAAAAAAAAAAAAsNjBzyYZMjZmZZbMzwsMLzYAAGAAAAAA00MziZMzwws1GAGYAzgNAAwMTbzMLzAAsZGMAYMDjBAYZGgZGkB",
        ["Raid ST"] = "CIEAAAAAAAAAAAAAAAAAAAAAAsZm5BYWGLzMjZGbLjxYmFbzYAAGAAAAAAkmZWMjZmxYmt2AwAGwgNAAwMTbzMLzAAsBmxAYMDjBAYZGgZGkB",
    },
    ["PALADIN_RETRIBUTION"] = {
        ["M+"] = "CYEAAAAAAAAAAAAAAAAAAAAAAAAAAAAMa22mZmlxMzMDAAAAAwMlhhZGbDz2wMbzYMGDzYjNMAAkZm2mZ2mBAsBYAwYGGYmZYDLzghxMGM",
        ["Raid ST"] = "CYEAAAAAAAAAAAAAAAAAAAAAAAAAAAAQz22MzsMMzAAAAAAwoMmhZGbDz2wMbzYMmZYGbsNMAAkZm2mZ2mBAsBYAwYGmBzYMbYZGMMmxgB",
    },
    ["PRIEST_DISCIPLINE"] = {
        ["M+"] = "CAQAAAAAAAAAAAAAAAAAAAAAAADsYY2YMDzMjZbsNzMzMMDAAAAAAAAAgxYZGMzMjNjZGsZamYAmZBDhxsMAjBLAAwYmZGDmBYmZ0MM",
        ["Raid ST"] = "CAQAAAAAAAAAAAAAAAAAAAAAAADsAzGjZGzMjZbsNzMzMMDAAAAAAAAAgZYZGMzMDmxMgpZiBYmFMEGzyAMGsAAAjZmZMMzAMzMTzwA",
    },
    ["PRIEST_HOLY"] = {
        ["M+"] = "CEQAAAAAAAAAAAAAAAAAAAAAAwYAAAAAAgZzwYWGMmZmZMzMjlZmZAAAAYMWmBzMzYzYmxAmpAAzsZmMbGAYMYzYsAoZMzYMMzstMADYA",
        ["Raid ST"] = "CEQAAAAAAAAAAAAAAAAAAAAAAwYAAAAAAAgZmlxYMzMDzMzYZGmBAAAwwsMDzMzMYGzAYmaAgZWMTmFDAMGsZmZWA0MMjxwMz2yAMDMA",
    },
    ["PRIEST_SHADOW"] = {
        ["M+"] = "CIQAAAAAAAAAAAAAAAAAAAAAAMMjZGAAAAAAAAAAAghZxMGLzMmZWmZYmx2MGzMzYDZGLmpBYGgZ2MDzmBgMGLAYGIjZmZMbjZ2WGgZiB",
        ["Raid ST"] = "CIQAAAAAAAAAAAAAAAAAAAAAAMMjZGAAAAAAAAAAAgxMMjxyMDzsNzwMsNzMmZmxGyMWMTDwMAzsZGmNDAZMWAwMQGzMzY2GzstMAzED",
    },
    ["ROGUE_ASSASSINATION"] = {
        ["M+"] = "CMQAAAAAAAAAAAAAAAAAAAAAAYmZmZzgBAAAAAmlBbzAAAAAAabbmZmZmZMmZmZ2mZZmBPwMzMzYYmxYAMwCMjRjZDklBsZsBYmhxA",
        ["Raid ST"] = "CMQAAAAAAAAAAAAAAAAAAAAAAYmZMbzgBAAAAAmlBLzAAAAAAabbmZmZmZMmZmZ2mZZmZGMmZmZMzYYAMwCMjRjZBklBsZAwMzgB",
    },
    ["ROGUE_OUTLAW"] = {
        ["M+"] = "CQQAAAAAAAAAAAAAAAAAAAAAAAgx2MGzMzMzsNzMzYmHYmFGmx0ygtZAAAAAAz22MzMMzMzMmZmtBAAAgBwAbwMGNmNAbTYhBAzMDM",
        ["Raid ST"] = "CQQAAAAAAAAAAAAAAAAAAAAAAAgx2MGjZMzsNzMzMjHwswDMzMLTLD2mBAAAAAMbbzMzwMzMzYmZ2GAAAAGADsBzY0Y2AsNhFGAMzMwA",
    },
    ["ROGUE_SUBTLETY"] = {
        ["M+"] = "CUQAAAAAAAAAAAAAAAAAAAAAAAgx2MAAAAAwsMGLTMbbjxMjZMMzMzYMbzYGbbzMzMzMjBjZ2GAAAAGMGwY2MMwAziWoFbYGwMDmxA",
        ["Raid ST"] = "CUQAAAAAAAAAAAAAAAAAAAAAAAgx2MAAAAAwsMGLTMbbjxMDDmZmZGjZbMzYbbmZmZmZMYMz2AAAAwgxsYWGYALglhJkZBzwMDwMGA",
    },
    ["SHAMAN_ELEMENTAL"] = {
        ["M+"] = "CYQAAAAAAAAAAAAAAAAAAAAAAAAAAAzMbLzMzYML2mhZMzAAAAAALmxwGsAzohGbAwsMzMjx2ipNmZMWmZmZMsMLGLmZGzsAAMDwMDMMMA",
        ["Raid ST"] = "CYQAAAAAAAAAAAAAAAAAAAAAAAAAAAzMbLzMmZmZZbbgxMDAAAAAsYGDbwCMjGasBAzyMzMGbLmwMzyYZmZmxwysMjFzMjZWAAGAzMwwwA",
    },
    ["SHAMAN_ENHANCEMENT"] = {
        ["M+"] = "CcQAAAAAAAAAAAAAAAAAAAAAAMzMjZmZmZmZmZmZGzAAAAAAAAAALwGMjFN2GAzEsBwsMjZMWWMwMz2YZmZmZwyYGAAgxYGxMDwgxA",
    },
    ["SHAMAN_RESTORATION"] = {
        ["M+"] = "CgQAAAAAAAAAAAAAAAAAAAAAAAAAAgBAAAAjZmZZZbMzMzYmZGzYGLwCMjNN2GQmB2YMDmtZGjmtlZGmxswixMjZsMLDAAGgZmBzMAwgB",
        ["Raid ST"] = "CgQAAAAAAAAAAAAAAAAAAAAAAAAAAgBAAAAzMzMLLbDzwYmZmZGzYBWgZspx2AyMwGjhZsNGz0stMzwMmFWMzMjZYWGAAYAzMDmZAgBD",
    },
    ["WARLOCK_AFFLICTION"] = {
        ["M+"] = "CkQAAAAAAAAAAAAAAAAAAAAAAwMjZGNbmxmZGzyAAAmZmlZzMzyYAgx22ADYCmhtADbDAAAGAAAzMjZMzsNzYGMzMzYYmZmBAMDMA",
        ["Raid ST"] = "CkQAAAAAAAAAAAAAAAAAAAAAAwMzMzoZhhZmZmlBAAYmZxyMzsMzAAjllBGwEMDbBG2GAAAmBAAwMDzMjBGmZmZGzgZmZGAwMwA",
    },
    ["WARLOCK_DEMONOLOGY"] = {
        ["M+"] = "CoQAAAAAAAAAAAAAAAAAAAAAAwMjZGNbmx2MzYWGAAAAAAAwYGDLwAbj2ohFDGLjZmZmZAgZMzYmZGgxMMzGAAYmZmZmZGsNzAMA",
        ["Raid ST"] = "CoQAy0jxIDofkwJmoH7WhvESoZmZMzoZjhZmxsMAAAAAAAjllZMzMsYYYmtZpNaGbGjZ2mlZmZYAgZYmZmZGMzMzMmZAAAGzMzMDzYZGDYA",
    },
    ["WARLOCK_DESTRUCTION"] = {
        ["M+"] = "CsQAAAAAAAAAAAAAAAAAAAAAAwMjZGNLmxiZGzysNzYsYmZZZmBAAzgZmZxCMwsY0YGAzWsxAAAjZYAAwMDGzMmZDAAwMzMDAAzwA",
        ["Raid ST"] = "CsQAAAAAAAAAAAAAAAAAAAAAAwMzMzoZjhZmxsMLjxMLGz2iZAAwMGzMzCYMjhFyAbDb0YhBAAGDwCAmZAmZGjZDAAwMzMAAMzwA",
    },
    ["WARRIOR_ARMS"] = {
        ["M+"] = "CcEAAAAAAAAAAAAAAAAAAAAAAgZmxsMzMzYGAAAghphxwMbLzMzMjZGzMAAAAAGbmB2iBsZGDLwAzoNaMYBYGMGMbmtBzMAgZmhB",
        ["Raid ST"] = "CcEAAAAAAAAAAAAAAAAAAAAAAAzMzsMzYmZAAAAMMNMGzMWmZmZGMmZAAAAAMzyMDslxYZZgFwAmhJkZwGwM2MbjBzsNAzMAMjhB",
    },
    ["WARRIOR_FURY"] = {
        ["M+"] = "CgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgGDjZMz2yMzMjZmxMjZMjZWmZGjZmlxMzAAAhB2glFjGzAysgZsAYGMGAMzAYYmZGMYA",
        ["Raid ST"] = "CgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgGDjxMsMzMzMDjZmZGzYmlZmxYmZbMzMAAQMWWGYBMBzwEYG2AmZ2Y2GAAMzYYMzMMYA",
    },
    ["WARRIOR_PROTECTION"] = {
        ["M+"] = "CkEAAAAAAAAAAAAAAAAAAAAAAkBAAGzMzMzMmxsZmZZGjxMNmxwyYmZYmxMDAAAAWGAmxAMwGssY0YGAzWMzGMzMzgZZAwMDAADwA",
        ["Raid ST"] = "CkEAAAAAAAAAAAAAAAAAAAAAA0yAAAzMzYmZGzMzmxsMjxYmGmZYZMzMDzYmBAAAALDAzYAGYDWWMaMDgZLmZDmxMDmtBAzMAAMAD",
    },
}









----------------------------------------------------------------------
-- PRESET WISHLISTS (addon-provided, read-only)
-- Auto-generated by tools/scrape_bis.py — do not edit manually.
-- Re-run the scraper to update data.
-- These are NEVER saved to MCSdb — they live in code and update with addon versions.
-- Users cannot edit these. They can copy items to their own (user) lists.
----------------------------------------------------------------------
MCS.PRESET_LISTS = {
    ["DEATHKNIGHT_BLOOD"] = {  -- updated: 2026/03/10
        ["Overall BiS"] = {
            { itemID = 49802, source = "Pit of Saron" },  -- Weapon: Garfrost's Two-Ton Hammer
            { itemID = 249970, source = "Tier Set" },  -- Head: Relentless Rider's Crown
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 249968, source = "Tier Set" },  -- Shoulders: Relentless Rider's Dreadthorns
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 249973, source = "" },  -- Chest: Relentless Rider's Cuirass
            { itemID = 237834, source = "Crafting" },  -- Wrist: Spellbreaker's Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 49808, source = "Pit of Saron" },  -- Belt: Bent Gold Belt
            { itemID = 249969, source = "Tier Set" },  -- Legs: Relentless Rider's Legguards
            { itemID = 249381, source = "Chimaerus" },  -- Boots: Greaves of the Unformed
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 251513, source = "Crafting" },  -- Ring: Loa Worshiper's Band
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249344, source = "Imperator Averzian" },  -- Trinket: Light Company Guidon
        },
        ["M+ BiS"] = {
            { itemID = 251168, source = "Maisara Caverns" },  -- Weapon: Liferipper's Cutlass
            { itemID = 151333, source = "Seat of the Triumvirate" },  -- Helm: Crown of the Dark Envoy
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 258587, source = "Skyreach" },  -- Shoulder: Spaulders of Scorching Ray
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 50272, source = "Pit of Saron" },  -- Chest: Frost Wyrm Ribcage
            { itemID = 263193, source = "Maisara Caverns" },  -- Bracers: Trollhunter's Bands
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 49808, source = "Pit of Saron" },  -- Belt: Bent Gold Belt
            { itemID = 251208, source = "Nexus-Point Xenas" },  -- Legs: Lightscarred Cuisses
            { itemID = 251091, source = "Windrunner Spire" },  -- Boots: Sabatons of Furious Revenge
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["DEATHKNIGHT_FROST"] = {  -- updated: 2026/03/16
        ["Overall BiS"] = {
            { itemID = 249277, source = "Lightblinded Vanguard" },  -- Weapon (2H): Bellamy's Final Judgement
            { itemID = 249281, source = "Fallen-King Salhadaar" },  -- Weapon (1H): Blade of the Final Twilight
            { itemID = 249970, source = "Tier Set" },  -- Head: Relentless Rider's Crown
            { itemID = 250247, source = "Seat of the Triumvirate" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 50234, source = "Pit of Saron" },  -- Shoulders: Shoulderplates of Frozen Blood
            { itemID = 239656, source = "Crafting/Misc" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249973, source = "Tier Set" },  -- Chest: Relentless Rider's Cuirass
            { itemID = 237834, source = "Crafting/Misc" },  -- Wrist: Spellbreaker's Bracers
            { itemID = 249971, source = "Tier Set" },  -- Gloves: Relentless Rider's Bonegrasps
            { itemID = 249380, source = "Crown of the Cosmos" },  -- Belt: Hate-Tied Waistchain
            { itemID = 249969, source = "Tier Set" },  -- Legs: Relentless Rider's Legguards
            { itemID = 249381, source = "Chimaerus" },  -- Boots: Greaves of the Unformed
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249344, source = "Imperator Averzian" },  -- Trinket: Light Company Guidon
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
        },
        ["M+ BiS"] = {
            { itemID = 251168, source = "Maisara Caverns" },  -- 2H Weapon: Liferipper's Cutlass
            { itemID = 251100, source = "Magister's Terrace" },  -- Mainhand 1H Weapon: Malfeasance Mallet
            { itemID = 237841, source = "Crafted by Blacksmithing" },  -- Offhand 1H Weapon: Spellbreaker's Ultimatum
            { itemID = 249970, source = "Matrix Catalyst" },  -- Helm: Relentless Rider's Crown
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 50234, source = "Pit of Saron" },  -- Shoulder: Shoulderplates of Frozen Blood
            { itemID = 239656, source = "Crafted by Leatherworking" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249973, source = "Matrix Catalyst" },  -- Chest: Relentless Rider's Cuirass
            { itemID = 237834, source = "Crafted by Blacksmithing" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 249971, source = "Matrix Catalyst" },  -- Gloves: Relentless Rider's Bonegrasps
            { itemID = 49808, source = "Pit of Saron" },  -- Belt: Bent Gold Belt
            { itemID = 249969, source = "Matrix Catalyst" },  -- Legs: Relentless Rider's Legguards
            { itemID = 251107, source = "Magister's Terrace" },  -- Boots: Oathsworn Stompers
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring #1: Platinum Star Band
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["DEATHKNIGHT_UNHOLY"] = {  -- updated: 2026/03/07
        ["Overall BiS"] = {
            { itemID = 249277, source = "Lightblinded Vanguard" },  -- Weapon: Bellamy's Final Judgement
            { itemID = 249970, source = "Tier Set" },  -- Head: Relentless Rider's Crown
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 50234, source = "Pit of Saron" },  -- Shoulders: Shoulderplates of Frozen Blood
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249973, source = "Tier Set" },  -- Chest: Relentless Rider's Cuirass
            { itemID = 237834, source = "Crafting" },  -- Wrist: Spellbreaker's Bracers
            { itemID = 249971, source = "Tier Set" },  -- Gloves: Relentless Rider's Bonegrasps
            { itemID = 249967, source = "Catalyst" },  -- Belt: Relentless Rider's Chain
            { itemID = 249969, source = "Tier Set" },  -- Legs: Relentless Rider's Legguards
            { itemID = 249381, source = "Chimaerus" },  -- Boots: Greaves of the Unformed
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249344, source = "Imperator Averzian" },  -- Trinket: Light Company Guidon
        },
        ["M+ BiS"] = {
            { itemID = 251168, source = "Maisara Caverns" },  -- 2H Weapon: Liferipper's Cutlass
            { itemID = 249970, source = "Matrix Catalyst" },  -- Helm: Relentless Rider's Crown
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 50234, source = "Pit of Saron" },  -- Shoulder: Shoulderplates of Frozen Blood
            { itemID = 239656, source = "Crafted by Leatherworking" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249973, source = "Matrix Catalyst" },  -- Chest: Relentless Rider's Cuirass
            { itemID = 237834, source = "Crafted by Blacksmithing" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 249971, source = "Matrix Catalyst" },  -- Gloves: Relentless Rider's Bonegrasps
            { itemID = 49808, source = "Pit of Saron" },  -- Belt: Bent Gold Belt
            { itemID = 249969, source = "Matrix Catalyst" },  -- Legs: Relentless Rider's Legguards
            { itemID = 251107, source = "Magister's Terrace" },  -- Boots: Oathsworn Stompers
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring #1: Platinum Star Band
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["DEMONHUNTER_HAVOC"] = {  -- updated: 2026/04/04
        ["Overall BiS"] = {
            { itemID = 260408, source = "Midnight Falls" },  -- Weapon: Lightless Lament
            { itemID = 249280, source = "Vaelgor & Ezzorak" },  -- Offhand: Emblazoned Sunglaive
            { itemID = 251109, source = "Magister's Terrace" },  -- Head: Spellsnap Shadowmask
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250031, source = "Tier Set" },  -- Shoulders: Devouring Reaver's Exhaustplates
            { itemID = 239656, source = "Crafting/Misc" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250036, source = "Tier Set" },  -- Chest: Devouring Reaver's Engine
            { itemID = 244576, source = "Crafting/Misc" },  -- Wrist: Silvermoon Agent's Deflectors
            { itemID = 250034, source = "Tier Set" },  -- Gloves: Devouring Reaver's Essence Grips
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 250032, source = "Tier Set" },  -- Legs: Devouring Reaver's Pistons
            { itemID = 258577, source = "Skyreach" },  -- Boots: Boots of Burning Focus
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
        },
        ["M+ BiS"] = {
            { itemID = 251175, source = "Maisara Caverns" },  -- Weapons: Soulblight Cleaver
            { itemID = 237840, source = "Blacksmithing" },  -- Alternative: Spellbreaker's Warglaive
            { itemID = 251109, source = "Magister's Terrace" },  -- Helm: Spellsnap Shadowmask
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250031, source = "Matrix Catalyst" },  -- Shoulder: Devouring Reaver's Exhaustplates
            { itemID = 239656, source = "Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250036, source = "Matrix Catalyst" },  -- Chest: Devouring Reaver's Engine
            { itemID = 244576, source = "Leatherworking" },  -- Bracers: Silvermoon Agent's Deflectors
            { itemID = 50264, source = "Vorasius" },  -- Alt. (No Craft): Chewed Leather Wristguards
            { itemID = 250034, source = "Matrix Catalyst" },  -- Gloves: Devouring Reaver's Essence Grips
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 250032, source = "Matrix Catalyst" },  -- Legs: Devouring Reaver's Pistons
            { itemID = 258577, source = "Skyreach" },  -- Boots: Boots of Burning Focus
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring #1: Platinum Star Band
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 193701, source = "Windrunner Spire" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["DEMONHUNTER_VENGEANCE"] = {  -- updated: 2026/03/21
        ["Overall BiS"] = {
            { itemID = 260408, source = "Midnight Falls" },  -- Weapon: Lightless Lament
            { itemID = 249298, source = "Fallen-King Salhadaar or Crafted" },  -- Offhand: Tormentor's Bladed Fists or  Spellbreaker's Warglaive
            { itemID = 250033, source = "Lightblinded Vanguard(Tier Set)" },  -- Head: Devouring Reaver's Intake
            { itemID = 151309, source = "Seat of the Triumvirate" },  -- Neck: Necklace of the Twisting Void
            { itemID = 250031, source = "Fallen-King Salhadaar(Tier Set)" },  -- Shoulders: Devouring Reaver's Exhaustplates
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud (with Loa) or  Adherent's Silken Shroud (with Weapon)
            { itemID = 151313, source = "Seat of the Triumvirate" },  -- Chest: Vest of the Void's Embrace
            { itemID = 50264, source = "Pit of Saron" },  -- Wrist: Chewed Leather Wristguards
            { itemID = 250034, source = "Vorasius(Tier Set)" },  -- Gloves: Devouring Reaver's Essence Grips
            { itemID = 49806, source = "Pit of Saron" },  -- Belt: Flayer's Black Belt
            { itemID = 250032, source = "Vaelgor & Ezzorak(Tier Set)" },  -- Legs: Devouring Reaver's Pistons
            { itemID = 251210, source = "Nexus Point Xenas" },  -- Boots: Eclipse Espadrilles
            { itemID = 251093, source = "Nexus Point Xenas" },  -- Ring Set: Omission of Light
            { itemID = 249920, source = "Midnight Falls" },  -- Ring (Defensive): Eye of Midnight
            { itemID = 251513, source = "Crafting" },  -- Ring: Loa Worshiper's Band (with above)
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249344, source = "Imperator Averzian" },  -- Trinket: Light Company Guidon
        },
        ["M+ BiS"] = {
            { itemID = 193717, source = "Algeth'ar Academy" },  -- Weapon Main-Hand: Mystakria's Harvester
            { itemID = 237840, source = "Crafted by Blacksmithing" },  -- Weapon Off-Hand: Spellbreaker's Warglaive
            { itemID = 250033, source = "Matrix Catalyst, or Lightblinded Vanguard in The Voidspire" },  -- Helm: Devouring Reaver's Intake
            { itemID = 151309, source = "Seat of the Triumvirate" },  -- Neck: Necklace of the Twisting Void
            { itemID = 250031, source = "Matrix Catalyst, or Fallen-King Salhadaar in The Voidspire" },  -- Shoulder: Devouring Reaver's Exhaustplates
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 251216, source = "Nexus-Point Xenas" },  -- Chest: Maledict Vest
            { itemID = 244576, source = "Crafted by Leatherworking" },  -- Bracers: Silvermoon Agent's Deflectors
            { itemID = 250034, source = "Matrix Catalyst, or Vorasius in The Voidspire" },  -- Gloves: Devouring Reaver's Essence Grips
            { itemID = 251166, source = "Maisara Caverns" },  -- Belt: Falconer's Cinch
            { itemID = 250032, source = "Matrix Catalyst, or Vaelgor and Ezzorak in The Voidspire" },  -- Legs: Devouring Reaver's Pistons
            { itemID = 251210, source = "Nexus-Point Xenas" },  -- Boots: Eclipse Espadrilles
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 49812, source = "Pit of Saron" },  -- Ring #2: Purloined Wedding Ring
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["DEMONHUNTER_DEVOURER"] = {  -- updated: 2026/03/15
        ["Overall BiS"] = {
            { itemID = 260408, source = "Midnight Falls" },  -- Weapon: Lightless Lament
            { itemID = 237840, source = "Crafting" },  -- Offhand: Spellbreaker's Warglaive crafted with  Darkmoon Sigil: Hunt
            { itemID = 250033, source = "Tier Set" },  -- Head: Devouring Reaver's Intake
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 250031, source = "Tier Set" },  -- Shoulders: Devouring Reaver's Exhaustplates
            { itemID = 249370, source = "Vaelgor & Ezzorak" },  -- Cloak: Draconic Nullcape
            { itemID = 250036, source = "Tier Set" },  -- Chest: Devouring Reaver's Engine
            { itemID = 193714, source = "Algeth'ar Academy" },  -- Wrist: Frenzyroot Cuffs
            { itemID = 250034, source = "Tier Set" },  -- Gloves: Devouring Reaver's Essence Grips
            { itemID = 244573, source = "Crafting" },  -- Belt: Silvermoon Agent's Utility Belt with  Arcanoweave Lining
            { itemID = 49817, source = "Pit of Saron" },  -- Legs: Shaggy Wyrmleather Leggings
            { itemID = 250035, source = "Catalyst" },  -- Boots: Devouring Reaver's Soul Flatteners
            { itemID = 249369, source = "Lightblinded Vanguard" },  -- Ring: Bond of Light
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249346, source = "Vaelgor & Ezzorak" },  -- Trinket: Vaelgor's Final Stare
        },
        ["M+ BiS"] = {
            { itemID = 193710, source = "Algeth'ar Academy" },  -- Main Hand: Spellboon Saber
            { itemID = 237840, source = "Blacksmithing" },  -- Off Hand: Spellbreaker's Warglaive
            { itemID = 250033, source = "Matrix Catalyst" },  -- Helm: Devouring Reaver's Intake
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250031, source = "Matrix Catalyst" },  -- Shoulder: Devouring Reaver's Exhaustplates
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 250036, source = "Matrix Catalyst" },  -- Chest: Devouring Reaver's Engine
            { itemID = 193714, source = "Matrix Catalyst" },  -- Bracers: Frenzyroot Cuffs
            { itemID = 250034, source = "Matrix Catalyst" },  -- Gloves: Devouring Reaver's Essence Grips
            { itemID = 244573, source = "Leatherworking" },  -- Belt: Silvermoon Agent's Utility Belt
            { itemID = 49817, source = "Pit of Saron" },  -- Legs: Shaggy Wyrmleather Leggings
            { itemID = 258577, source = "Skyreach" },  -- Boots: Boots of Burning Focus
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring #2: Bifurcation Band
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #2: Emberwing Feather
        },
    },
    ["DRUID_BALANCE"] = {  -- updated: 2026/03/21
        ["Overall BiS"] = {
            { itemID = 249283, source = "Belo'ren" },  -- Weapon: Belo'melorn, the Shattered Talon
            { itemID = 245769, source = "Crafting" },  -- Offhand: Aln'hara Lantern
            { itemID = 250024, source = "Tier Set" },  -- Head: Branches of the Luminous Bloom
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250022, source = "Tier Set" },  -- Shoulders: Seedpods of the Luminous Bloom
            { itemID = 249370, source = "Vaelgor & Ezzorak" },  -- Cloak: Draconic Nullcape
            { itemID = 250027, source = "Tier Set" },  -- Chest: Trunk of the Luminous Bloom
            { itemID = 244576, source = "Crafting" },  -- Wrist: Silvermoon Agent's Deflectors
            { itemID = 251113, source = "Magister's Terrace" },  -- Gloves: Gloves of Viscous Goo
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 250023, source = "Tier Set" },  -- Legs: Phloemwraps of the Luminous Bloom
            { itemID = 249382, source = "Crown of the Cosmos" },  -- Boots: Canopy Walker's Footwraps
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring: Occlusion of Void
            { itemID = 249346, source = "Vaelgor & Ezzorak" },  -- Trinket: Vaelgor's Final Stare
            { itemID = 249809, source = "Crown of the Cosmos" },  -- Trinket: Locus-Walker's Ribbon
        },
        ["M+ BiS"] = {
            { itemID = 251201, source = "Nexus-Point Xenas" },  -- Weapon (Two-Hand): Corespark Multitool
            { itemID = 251178, source = "Maisara Caverns & Algeth'ar Academy" },  -- Weapon (Main-Hand/Off-Hand): Ceremonial Hexblade
            { itemID = 250024, source = "Lightblinded Vanguard in The Voidspire" },  -- Helm: Branches of the Luminous Bloom
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250022, source = "Fallen-King Salhadaar in The Voidspire" },  -- Shoulder: Seedpods of the Luminous Bloom
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 250027, source = "Chimaerus in The Dreamrift" },  -- Chest: Trunk of the Luminous Bloom
            { itemID = 50264, source = "Pit of Saron" },  -- Bracers: Chewed Leather Wristguards
            { itemID = 244575, source = "Leatherworking" },  -- Gloves: Silvermoon Agent's Handwraps
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 250023, source = "Vaelgor and Ezzorak in The Voidspire" },  -- Legs: Phloemwraps of the Luminous Bloom
            { itemID = 244569, source = "Leatherworking" },  -- Boots: Silvermoon Agent's Sneakers
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring #1: Bifurcation Band
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #1: Emberwing Feather
            { itemID = 250223, source = "Maisara Caverns" },  -- Trinket #2: Soulcatcher's Charm
        },
    },
    ["DRUID_FERAL"] = {  -- updated: 2026/03/17
        ["Overall BiS"] = {
            { itemID = 249302, source = "Vorasius" },  -- Weapon: Inescapable Reach
            { itemID = 250024, source = "Tier Set" },  -- Head: Branches of the Luminous Bloom
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250022, source = "Tier Set" },  -- Shoulders: Seedpods of the Luminous Bloom
            { itemID = 249370, source = "Vaelgor & Ezzorak" },  -- Cloak: Draconic Nullcape
            { itemID = 250027, source = "Tier Set" },  -- Chest: Trunk of the Luminous Bloom
            { itemID = 244576, source = "Crafting/Misc" },  -- Wrist: Silvermoon Agent's Deflectors
            { itemID = 244575, source = "Crafting/Misc" },  -- Gloves: Silvermoon Agent's Handwraps
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 250023, source = "Tier Set" },  -- Legs: Phloemwraps of the Luminous Bloom
            { itemID = 249382, source = "Crown of the Cosmos" },  -- Boots: Canopy Walker's Footwraps
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring: Bifurcation Band
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
            { itemID = 249806, source = "Belo'ren" },  -- Trinket: Radiant Plume
        },
        ["M+ BiS"] = {
            { itemID = 251077, source = "Windrunner Spire" },  -- Weapon: Roostwarden's Bough
            { itemID = 245771, source = "Inscription" },  -- Weapon (Alt): Aln'hara Pikestaff
            { itemID = 250024, source = "Matrix Catalyst" },  -- Helm: Branches of the Luminous Bloom
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 251092, source = "Windrunner Spire" },  -- Shoulder: Fallen Grunt's Mantle
            { itemID = 239656, source = "Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250027, source = "Matrix Catalyst" },  -- Chest: Trunk of the Luminous Bloom
            { itemID = 244576, source = "Leatherworking" },  -- Bracers: Silvermoon Agent's Deflectors
            { itemID = 193714, source = "Algeth'ar Academy" },  -- Alt. (No Craft): Frenzyroot Cuffs
            { itemID = 250025, source = "Vorasius" },  -- Gloves: Arbortenders of the Luminous Bloom
            { itemID = 49806, source = "Pit of Saron" },  -- Belt: Flayer's Black Belt
            { itemID = 250023, source = "Matrix Catalyst" },  -- Legs: Phloemwraps of the Luminous Bloom
            { itemID = 258577, source = "Skyreach" },  -- Boots: Boots of Burning Focus
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 193701, source = "Windrunner Spire" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #2: Heart of Wind
        },
    },
    ["DRUID_GUARDIAN"] = {  -- updated: 2026/03/21
        ["Overall BiS"] = {
            { itemID = 249278, source = "Chimaerus" },  -- Weapon: Alnscorned Spire
            { itemID = 249913, source = "Seat of the Triumvirate" },  -- Head: Mask of Darkest Intent
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 250022, source = "Tier Set" },  -- Shoulders: Seedpods of the Luminous Bloom
            { itemID = 249370, source = "Vaelgor & Ezzorak" },  -- Cloak: Draconic Nullcape
            { itemID = 250027, source = "Tier Set" },  -- Chest: Trunk of the Luminous Bloom
            { itemID = 249327, source = "Vorasius" },  -- Wrist: Void-Skinned Bracers
            { itemID = 250025, source = "Tier Set" },  -- Gloves: Arbortenders of the Luminous Bloom
            { itemID = 249374, source = "Chimaerus" },  -- Belt: Scorn-Scarred Shul'ka's Belt
            { itemID = 250023, source = "Tier Set" },  -- Legs: Phloemwraps of the Luminous Bloom
            { itemID = 249334, source = "Imperator Averzian" },  -- Boots: Void-Claimed Shinkickers
            { itemID = 251093, source = "Nexus Point Xenas" },  -- Ring: Omission of Light
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
        },
        ["M+ BiS"] = {
            { itemID = 251162, source = "Maisara Caverns" },  -- Weapon: Traitor's Talon
            { itemID = 151336, source = "Seat of the Triumvirate" },  -- Helm: Voidlashed Hood
            { itemID = 251096, source = "Windrunner Spire" },  -- Neck: Pendant of Aching Grief
            { itemID = 250022, source = "Matrix Catalyst" },  -- Shoulder: Seedpods of the Luminous Bloom
            { itemID = 251161, source = "Maisara Caverns" },  -- Cloak: Soulhunter's Mask
            { itemID = 250027, source = "Matrix Catalyst" },  -- Chest: Trunk of the Luminous Bloom
            { itemID = 244576, source = "Crafted by Leatherworking" },  -- Bracers: Silvermoon Agent's Deflectors
            { itemID = 250025, source = "Matrix Catalyst" },  -- Gloves: Arbortenders of the Luminous Bloom
            { itemID = 244573, source = "Crafted by Leatherworking" },  -- Belt: Silvermoon Agent's Utility Belt
            { itemID = 250023, source = "Matrix Catalyst" },  -- Legs: Phloemwraps of the Luminous Bloom
            { itemID = 251210, source = "Nexus-Point Xenas" },  -- Boots: Eclipse Espadrilles
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #1: Emberwing Feather
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #2: Algeth'ar Puzzle Box
        },
    },
    ["DRUID_RESTORATION"] = {  -- updated: 2026/03/08
        ["Overall BiS"] = {
            { itemID = 250024, source = "Raid | Catalyst | Vault" },  -- Helm: Branches of the Luminous Bloom
            { itemID = 250247, source = "Midnight Falls (Raid)" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250022, source = "Raid | Catalyst | Vault" },  -- Shoulders: Seedpods of the Luminous Bloom
            { itemID = 249370, source = "Vaelgor & Ezzorak (Raid)" },  -- Cape: Draconic Nullcape
            { itemID = 251216, source = "Nexus Point Xenas" },  -- Chest: Maledict Vest
            { itemID = 193714, source = "Algeth'ar Academy" },  -- Bracers: Frenzyroot Cuffs
            { itemID = 250025, source = "Raid | Catalyst | Vault" },  -- Gloves: Arbortenders of the Luminous Bloom
            { itemID = 249314, source = "Fallen-King Salhadaar (Raid)" },  -- Belt: Twisted Twilight Sash
            { itemID = 250023, source = "Raid | Catalyst | Vault" },  -- Legs: Phloemwraps of the Luminous Bloom
            { itemID = 251210, source = "Nexus Point Xenas" },  -- Boots: Eclipse Espadrilles
            { itemID = 249920, source = "Midnight Falls (Raid)" },  -- Ring: Eye of Midnight
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring: Bifurcation Band
            { itemID = 249809, source = "Crown of the Cosmos (Raid)" },  -- Trinkets: Locus-Walker's Ribbon
            { itemID = 249346, source = "Vaelgor & Ezzorak (Raid)" },  -- Trinkets: Vaelgor's Final Stare
            { itemID = 249283, source = "Belo'ren (Raid)" },  -- 1h Weapon: Belo'melorn, the Shattered Talon
            { itemID = 249922, source = "Chimaerus (Raid)" },  -- Offhand: Tome of Alnscorned Regret
        },
        ["M+ BiS"] = {
            { itemID = 250024, source = "Lightblinded Vanguard - The Voidspire" },  -- Helm: Branches of the Luminous Bloom
            { itemID = 251096, source = "Windrunner Spire" },  -- Neck: Pendant of Aching Grief
            { itemID = 250022, source = "Fallen-King Salhadaar - The Voidspire" },  -- Shoulders: Seedpods of the Luminous Bloom
            { itemID = 193712, source = "Algeth'ar Academy" },  -- Cape: Potion-Stained Cloak
            { itemID = 251216, source = "Nexus-Point Xenas" },  -- Chest: Maledict Vest
            { itemID = 193714, source = "Algeth'ar Academy" },  -- Bracers: Frenzyroot Cuffs
            { itemID = 250025, source = "Vorasius - The Voidspire" },  -- Gloves: Arbortenders of the Luminous Bloom
            { itemID = 251166, source = "Maisara Caverns" },  -- Belt: Falconer's Cinch
            { itemID = 250023, source = "Vaelgor and Ezzorak - The Voidspire" },  -- Legs: Phloemwraps of the Luminous Bloom
            { itemID = 251121, source = "Magister's Terrace" },  -- Boots: Domanaar's Dire Treads
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring: Omission of Light
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring: Bifurcation Band
            { itemID = 193718, source = "Algeth'ar Academy" },  -- Trinkets: Emerald Coach's Whistle
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinkets: Heart of Wind
            { itemID = 193707, source = "Algeth'ar Academy" },  -- 2h Weapon: Final Grade
        },
    },
    ["EVOKER_AUGMENTATION"] = {  -- updated: 2026/03/29
        ["Overall BiS"] = {
            { itemID = 251178, source = "Maisara Caverns" },  -- Weapon: Ceremonial Hexblade
            { itemID = 249276, source = "Vorasius" },  -- Offhand: Grimoire of the Eternal Light
            { itemID = 133506, source = "Pit of Saron" },  -- Head: Horns of the Spurned Val'kyr
            { itemID = 249337, source = "Fallen-King Salhadaar" },  -- Neck: Ribbon of Coiled Malice
            { itemID = 249995, source = "Tier Set" },  -- Shoulders: Beacons of the Black Talon
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250000, source = "Tier Set" },  -- Chest: Frenzyward of the Black Talon
            { itemID = 244584, source = "Crafting" },  -- Wrist: Farstrider's Plated Bracers
            { itemID = 249998, source = "Tier Set" },  -- Gloves: Enforcer's Grips of the Black Talon
            { itemID = 49810, source = "Pit of Saron" },  -- Belt: Scabrous Zombie Leather Belt
            { itemID = 249996, source = "Tier Set" },  -- Legs: Greaves of the Black Talon
            { itemID = 249999, source = "The Catalyst" },  -- Boots: Spelltreads of the Black Talon
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 49812, source = "Pit of Saron" },  -- Ring: Purloined Wedding Ring
            { itemID = 249810, source = "Midnight Falls" },  -- Trinket: Shadow of the Empyrean Requiem
            { itemID = 250223, source = "Maisara Caverns" },  -- Trinket: Soulcatcher's Charm
        },
        ["M+ BiS"] = {
            { itemID = 251178, source = "Maisara Caverns" },  -- Weapons: Ceremonial Hexblade
            { itemID = 49824, source = "Pit of Saron" },  -- Head: Horns of the Spurned Val'kyr
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249995, source = "Matrix Catalyst" },  -- Shoulder: Beacons of the Black Talon
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250000, source = "Matrix Catalyst" },  -- Chest: Frenzyward of the Black Talon
            { itemID = 244584, source = "Crafted by Leatherworking" },  -- Wrist: Farstrider's Plated Bracers
            { itemID = 249998, source = "Matrix Catalyst" },  -- Hands: Enforcer's Grips of the Black Talon
            { itemID = 49810, source = "Pit of Saron" },  -- Waist: Scabrous Zombie Leather Belt
            { itemID = 249996, source = "Matrix Catalyst" },  -- Legs: Greaves of the Black Talon
            { itemID = 193715, source = "Algeth'ar Academy" },  -- Feet: Boots of Explosive Growth
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Rings: Occlusion of Void
            { itemID = 250223, source = "Maisara Caverns" },  -- Top Trinkets: Soulcatcher's Charm
        },
    },
    ["EVOKER_DEVASTATION"] = {  -- updated: 2026/03/17
        ["Overall BiS"] = {
            { itemID = 249283, source = "Belo'ren" },  -- Weapon: Belo'melorn, the Shattered Talon
            { itemID = 249276, source = "Vorasius" },  -- Offhand: Grimoire of the Eternal Light
            { itemID = 249997, source = "Tier Set" },  -- Head: Hornhelm of the Black Talon
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 249995, source = "Tier Set" },  -- Shoulders: Beacons of the Black Talon
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250000, source = "Tier Set" },  -- Chest: Frenzyward of the Black Talon
            { itemID = 244584, source = "Crafting" },  -- Wrist: Farstrider's Plated Bracers
            { itemID = 249325, source = "Crown of the Cosmos" },  -- Gloves: Untethered Berserker's Grips
            { itemID = 49810, source = "Pit of Saron" },  -- Belt: Scabrous Zombie Leather Belt
            { itemID = 249996, source = "Tier Set" },  -- Legs: Greaves of the Black Talon
            { itemID = 249377, source = "Belo'ren" },  -- Boots: Darkstrider Treads
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249346, source = "Vaelgor & Ezzorak" },  -- Trinket: Vaelgor's Final Stare
            { itemID = 249809, source = "Crown of the Cosmos" },  -- Trinket: Locus-Walker's Ribbon
        },
        ["M+ BiS"] = {
            { itemID = 251201, source = "Nexus-Point Xenas" },  -- Weapon: Corespark Multitool
            { itemID = 249997, source = "Matrix Catalyst" },  -- Head: Hornhelm of the Black Talon
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249995, source = "Matrix Catalyst" },  -- Shoulder: Beacons of the Black Talon
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250000, source = "Matrix Catalyst" },  -- Chest: Frenzyward of the Black Talon
            { itemID = 251079, source = "Windrunner Spire" },  -- Wrist: Amberfrond Bracers
            { itemID = 249998, source = "Matrix Catalyst" },  -- Hands: Enforcer's Grips of the Black Talon
            { itemID = 49810, source = "Pit of Saron" },  -- Waist: Scabrous Zombie Leather Belt
            { itemID = 249996, source = "Matrix Catalyst" },  -- Legs: Greaves of the Black Talon
            { itemID = 251084, source = "Windrunner Spire" },  -- Feet: Whipcoil Sabatons
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring 1: Occlusion of Void
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring 2: Omission of Light
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket 1/td>: Emberwing Feather
            { itemID = 250258, source = "Maisara Caverns" },  -- Trinket 2: Vessel of Tortured Souls
        },
    },
    ["EVOKER_PRESERVATION"] = {  -- updated: 2026/02/25
        ["Overall BiS"] = {
            { itemID = 249914, source = "Midnight Falls (Raid)" },  -- Helm: Oblivion Guise
            { itemID = 250247, source = "Midnight Falls (Raid)" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 249995, source = "Raid | Catalyst | Vault" },  -- Shoulders: Beacons of the Black Talon
            { itemID = 251206, source = "Nexus Point Xenas" },  -- Cape: Fluxweave Cloak
            { itemID = 250000, source = "Raid | Catalyst | Vault" },  -- Chest: Frenzyward of the Black Talon
            { itemID = 251079, source = "Windrunner Spire" },  -- Bracers: Amberfrond Bracers
            { itemID = 249998, source = "Raid | Catalyst | Vault" },  -- Gloves: Enforcer's Grips of the Black Talon
            { itemID = 193722, source = "Algeth'ar Academy" },  -- Belt: Azure Belt of Competition
            { itemID = 249996, source = "Raid | Catalyst | Vault" },  -- Legs: Greaves of the Black Talon
            { itemID = 251084, source = "Windrunner Spire" },  -- Boots: Whipcoil Sabatons
            { itemID = 249369, source = "Lightblinded Vanguard (Raid)" },  -- Ring: Bond of Light
            { itemID = 249920, source = "Midnight Falls (Raid)" },  -- Ring: Eye of Midnight
            { itemID = 249346, source = "Vaelgor & Ezzorak (Raid)" },  -- Trinkets: Vaelgor's Final Stare
            { itemID = 249809, source = "Crown of the Cosmos (Raid)" },  -- Trinkets: Locus-Walker's Ribbon
            { itemID = 258514, source = "Seat of the Triumvirate" },  -- 2h Weapon: Umbral Spire of Zuraal
        },
        ["M+ BiS"] = {
            { itemID = 258514, source = "Seat of the Triumvirate" },  -- Weapon: Umbral Spire of Zuraal
            { itemID = 251119, source = "Magister's Terrace" },  -- Helm: Vortex Visage
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249995, source = "Matrix Catalyst" },  -- Shoulder: Beacons of the Black Talon
            { itemID = 251206, source = "Nexus-Point Xenas" },  -- Cloak: Fluxweave Cloak
            { itemID = 250000, source = "Matrix Catalyst" },  -- Chest: Frenzyward of the Black Talon
            { itemID = 251079, source = "Windrunner Spire" },  -- Bracers: Amberfrond Bracers
            { itemID = 249998, source = "Matrix Catalyst" },  -- Gloves: Enforcer's Grips of the Black Talon
            { itemID = 244611, source = "Crafted by Leatherworking" },  -- Belt: World Tender's Barkclasp
            { itemID = 249996, source = "Matrix Catalyst" },  -- Legs: Greaves of the Black Talon
            { itemID = 244610, source = "Crafted by Leatherworking" },  -- Boots: World Tender's Rootslippers
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring #1: Bifurcation Band
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #2: Emberwing Feather
        },
    },
    ["HUNTER_BEAST_MASTERY"] = {  -- updated: 2026/03/22
        ["Overall BiS"] = {
            { itemID = 251174, source = "Maisara Caverns" },  -- Weapon: Deceiver's Rotbow
            { itemID = 249988, source = "Tier Set" },  -- Head: Primal Sentry's Maw
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 151323, source = "Seat of the Triumvirate" },  -- Shoulders: Pauldrons of the Void Hunter
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 249991, source = "Tier Set" },  -- Chest: Primal Sentry's Scaleplate
            { itemID = 251209, source = "Nexus Point Xenas" },  -- Wrist: Corewarden Cuffs
            { itemID = 249989, source = "Tier Set" },  -- Gloves: Primal Sentry's Talonguards
            { itemID = 244611, source = "Leatherworking" },  -- Belt: World Tender's Barkclasp
            { itemID = 249987, source = "Tier Set" },  -- Legs: Primal Sentry's Legguards
            { itemID = 244610, source = "Leatherworking" },  -- Boots: World Tender's Rootslippers
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249369, source = "Lightblinded Vanguard" },  -- Ring: Bond of Light
            { itemID = 249806, source = "Belo'ren" },  -- Trinket: Radiant Plume
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
        },
        ["M+ BiS"] = {
            { itemID = 249988, source = "Matrix Catalyst" },  -- Helm: Primal Sentry's Maw
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 151323, source = "Seat of the Triumvirate" },  -- Shoulder: Pauldrons of the Void Hunter
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 249991, source = "Matrix Catalyst" },  -- Chest: Primal Sentry's Scaleplate
            { itemID = 151321, source = "Seat of the Triumvirate" },  -- Bracers: Darkfang Scale Wristguards
            { itemID = 249989, source = "Matrix Catalyst" },  -- Gloves: Primal Sentry's Talonguards
            { itemID = 244611, source = "Leatherworking" },  -- Belt: World Tender's Barkclasp
            { itemID = 249987, source = "Matrix Catalyst" },  -- Legs: Primal Sentry's Legguards
            { itemID = 244610, source = "Leatherworking" },  -- Boots: World Tender's Rootslippers
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
            { itemID = 251174, source = "Maisara Caverns" },  -- Weapon: Deceiver's Rotbow
        },
    },
    ["HUNTER_MARKSMANSHIP"] = {  -- updated: 2026/03/07
        ["Overall BiS"] = {
            { itemID = 249288, source = "Imperator Averzian" },  -- Weapon: Ranger-Captain's Lethal Recurve
            { itemID = 249988, source = "Tier Set" },  -- Head: Primal Sentry's Maw
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 151323, source = "Seat of the Triumvirate" },  -- Shoulders: Pauldrons of the Void Hunter
            { itemID = 249335, source = "Imperator Averzian" },  -- Cloak: Imperator's Banner
            { itemID = 249991, source = "Tier Set" },  -- Chest: Primal Sentry's Scaleplate
            { itemID = 249304, source = "Fallen-King Salhadaar" },  -- Wrist: Fallen King's Cuffs
            { itemID = 249989, source = "Tier Set" },  -- Gloves: Primal Sentry's Talonguards
            { itemID = 244611, source = "Crafting" },  -- Belt: World Tender's Barkclasp
            { itemID = 249987, source = "Tier Set" },  -- Legs: Primal Sentry's Legguards
            { itemID = 244610, source = "Crafting" },  -- Boots: World Tender's Rootslippers
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249336, source = "Vorasius" },  -- Ring: Signet of the Starved Beast
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
            { itemID = 260235, source = "Belo'ren" },  -- Trinket: Umbral Plume
        },
        ["M+ BiS"] = {
            { itemID = 249988, source = "Matrix Catalyst" },  -- Helm: Primal Sentry's Maw
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 151323, source = "Seat of the Triumvirate" },  -- Shoulder: Pauldrons of the Void Hunter
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 249991, source = "Matrix Catalyst" },  -- Chest: Primal Sentry's Scaleplate
            { itemID = 151321, source = "Seat of the Triumvirate" },  -- Bracers: Darkfang Scale Wristguards
            { itemID = 249989, source = "Matrix Catalyst" },  -- Gloves: Primal Sentry's Talonguards
            { itemID = 244611, source = "Leatherworking" },  -- Belt: World Tender's Barkclasp
            { itemID = 249987, source = "Matrix Catalyst" },  -- Legs: Primal Sentry's Legguards
            { itemID = 244610, source = "Leatherworking" },  -- Boots: World Tender's Rootslippers
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring #1: Platinum Star Band
            { itemID = 151308, source = "Seat of the Triumvirate" },  -- Ring #2: Eredath Seal of Nobility
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
            { itemID = 251095, source = "Windrunner Spire" },  -- Weapon: Hurricane's Heart
        },
    },
    ["HUNTER_SURVIVAL"] = {  -- updated: 2026/04/02
        ["Overall BiS"] = {
            { itemID = 251077, source = "Windrunner Spire" },  -- 2H Weapon: Roostwarden's Bough
            { itemID = 249284, source = "Belo'ren" },  -- Main Hand: Belo'ren's Swift Talon
            { itemID = 237837, source = "Crafting" },  -- Off Hand: Farstrider's Mercy
            { itemID = 249988, source = "Tier Set" },  -- Head: Primal Sentry's Maw
            { itemID = 250247, source = "L'ura (March on Quel'Danas)" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 151323, source = "The Seat of the Triumvirate" },  -- Shoulders: Pauldrons of the Void Hunter
            { itemID = 249370, source = "Vaelgor" },  -- Cloak: Draconic Nullcape
            { itemID = 249991, source = "Tier Set" },  -- Chest: Primal Sentry's Scaleplate
            { itemID = 249304, source = "Fallen-King Salhadaar" },  -- Wrist: Fallen King's Cuffs
            { itemID = 249989, source = "Tier Set" },  -- Gloves: Primal Sentry's Talonguards
            { itemID = 249371, source = "Chimaerus" },  -- Belt: Scornbane Waistguard
            { itemID = 249987, source = "Tier Set" },  -- Legs: Primal Sentry's Legguards
            { itemID = 244577, source = "Crafting" },  -- Boots: Farstrider's Razor Talons
            { itemID = 251093, source = "Nexus Point Xenas" },  -- Ring: Omission of Light
            { itemID = 251217, source = "Nexus Point Xenas" },  -- Ring: Occlusion of Void
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
            { itemID = 249806, source = "Belo'ren" },  -- Trinket: Radiant Plume
        },
        ["M+ BiS"] = {
            { itemID = 249988, source = "Matrix Catalyst" },  -- Helm: Primal Sentry's Maw
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 151323, source = "Seat of the Triumvirate" },  -- Shoulder: Pauldrons of the Void Hunter
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 249991, source = "Matrix Catalyst" },  -- Chest: Primal Sentry's Scaleplate
            { itemID = 151321, source = "Seat of the Triumvirate" },  -- Bracers: Darkfang Scale Wristguards
            { itemID = 249989, source = "Matrix Catalyst" },  -- Gloves: Primal Sentry's Talonguards
            { itemID = 244611, source = "Leatherworking" },  -- Belt: World Tender's Barkclasp
            { itemID = 249987, source = "Matrix Catalyst" },  -- Legs: Primal Sentry's Legguards
            { itemID = 244610, source = "Leatherworking" },  -- Boots: World Tender's Rootslippers
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
            { itemID = 251077, source = "Windrunner Spire" },  -- Sentinel Weapon: Roostwarden's Bough
            { itemID = 251212, source = "Nexus-Point Xenas" },  -- Pack Leader Main Hand: Radiant Slicer
            { itemID = 237837, source = "Blacksmithing" },  -- Pack Leader Off-Hand: Farstrider's Mercy
        },
    },
    ["MAGE_ARCANE"] = {  -- updated: 2026/03/07
        ["Overall BiS"] = {
            { itemID = 258218, source = "Skyreach" },  -- Weapon: Skybreaker's Blade
            { itemID = 251094, source = "Windrunner Spire" },  -- Offhand: Sigil of the Restless Heart
            { itemID = 250060, source = "Tier Set" },  -- Head: Voidbreaker's Veil
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250058, source = "Tier Set" },  -- Shoulders: Voidbreaker's Leyline Nexi
            { itemID = 239661, source = "Crafting" },  -- Cloak: Arcanoweave Cloak
            { itemID = 250063, source = "Tier Set" },  -- Chest: Voidbreaker's Robe
            { itemID = 239660, source = "Crafting" },  -- Wrist: Arcanoweave Bracers
            { itemID = 250061, source = "Tier Set" },  -- Gloves: Voidbreaker's Gloves
            { itemID = 249376, source = "Belo'ren" },  -- Belt: Whisper-Inscribed Sash
            { itemID = 251090, source = "Windrunner Spire" },  -- Legs: Commander's Faded Breeches
            { itemID = 249373, source = "Chimaerus" },  -- Boots: Dream-Scorched Striders
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249346, source = "Vaelgor & Ezzorak" },  -- Trinket: Vaelgor's Final Stare
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
        },
        ["M+ BiS"] = {
            { itemID = 258218, source = "Skyreach" },  -- Main-hand: Skybreaker's Blade
            { itemID = 251094, source = "Windrunner Spire" },  -- Off-hand: Sigil of the Restless Heart
            { itemID = 258047, source = "Skyreach. The staff is very slightly worse than Main-hand +" },  -- Alternative Weapon (Staff): Spire of the Furious Construct
            { itemID = 250060, source = "Matrix Catalyst" },  -- Head: Voidbreaker's Veil
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250058, source = "Matrix Catalyst" },  -- Shoulder: Voidbreaker's Leyline Nexi
            { itemID = 239661, source = "Crafted by Tailoring" },  -- Cloak: Arcanoweave Cloak
            { itemID = 250063, source = "Matrix Catalyst" },  -- Chest: Voidbreaker's Robe
            { itemID = 239660, source = "Crafted by Tailoring" },  -- Wrist: Arcanoweave Bracers
            { itemID = 250061, source = "Matrix Catalyst" },  -- Hands: Voidbreaker's Gloves
            { itemID = 251102, source = "Magister's Terrace" },  -- Waist: Clasp of Compliance
            { itemID = 251090, source = "The Great Vault / Windrunner Spire" },  -- Legs: Commander's Faded Breeches
            { itemID = 251167, source = "Maisara Caverns" },  -- Feet: Nightprey Stalkers
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring 1: Platinum Star Band
            { itemID = 151308, source = "Seat of the Triumvirate" },  -- ring 2: Eredath Seal of Nobility
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket 1: Emberwing Feather
            { itemID = 250258, source = "Maisara Caverns" },  -- Trinket 2: Vessel of Tortured Souls
        },
    },
    ["MAGE_FIRE"] = {  -- updated: 2026/03/17
        ["Overall BiS"] = {
            { itemID = 249286, source = "Midnight Falls" },  -- Weapon: Brazier of the Dissonant Dirge
            { itemID = 250060, source = "Tier Set" },  -- Head: Voidbreaker's Veil
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250058, source = "Tier Set" },  -- Shoulders: Voidbreaker's Leyline Nexi
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249912, source = "Midnight Falls" },  -- Chest: Robes of Endless Oblivion
            { itemID = 239648, source = "Crafting" },  -- Wrist: Martyr's Bindings
            { itemID = 250061, source = "Tier Set" },  -- Gloves: Voidbreaker's Gloves
            { itemID = 249376, source = "Belo'ren" },  -- Belt: Whisper-Inscribed Sash
            { itemID = 250059, source = "Tier Set" },  -- Legs: Voidbreaker's Britches
            { itemID = 258584, source = "Skyreach" },  -- Boots: Lightbinder Treads
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249369, source = "Lightblinded Vanguard" },  -- Ring: Bond of Light
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket: Emberwing Feather
            { itemID = 249809, source = "Crown of the Cosmos" },  -- Trinket: Locus-Walker's Ribbon
        },
        ["M+ BiS"] = {
            { itemID = 193710, source = "Algeth'ar Academy" },  -- Main-hand: Spellboon Saber
            { itemID = 258472, source = "Windrunner Spire" },  -- Off-hand: Rukhran's Solar Reliquary
            { itemID = 251201, source = "Nexus-Point Xenas." },  -- Alternative Weapon (Any weapon with Haste will be very close, so lots of flexibility!): Corespark Multitool
            { itemID = 250060, source = "Matrix Catalyst" },  -- Head: Voidbreaker's Veil
            { itemID = 151309, source = "Seat of the Triumvirate" },  -- Neck: Necklace of the Twisting Void
            { itemID = 250058, source = "Matrix Catalyst" },  -- Shoulder: Voidbreaker's Leyline Nexi
            { itemID = 239656, source = "Crafted by Tailoring with  Arcanoweave Lining and Haste + Mastery" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 49825, source = "Pit of Saron" },  -- Chest: Palebone Robes
            { itemID = 239648, source = "Crafted by Tailoring with  Arcanoweave Lining and Haste + Mastery" },  -- Wrist: Martyr's Bindings
            { itemID = 250061, source = "Matrix Catalyst" },  -- Hands: Voidbreaker's Gloves
            { itemID = 50263, source = "Pit of Saron" },  -- Waist: Braid of Salt and Fire
            { itemID = 250059, source = "Matrix Catalyst" },  -- Legs: Voidbreaker's Britches
            { itemID = 258584, source = "Skyreach" },  -- Feet: Lightbinder Treads
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring 1: Omission of Light
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring 2 — if you also have  Omission of Light: Occlusion of Void
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring 2 — without  Omission of Light: Bifurcation Band
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket 1: Emberwing Feather
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket 2: Heart of Wind
        },
    },
    ["MAGE_FROST"] = {  -- updated: 2026/04/11
        ["Overall BiS"] = {
            { itemID = 258218, source = "Skyreach" },  -- Weapon: Skybreaker's Blade
            { itemID = 245769, source = "Crafting" },  -- Off Hand: Aln'hara Lantern
            { itemID = 250060, source = "Tier Set" },  -- Head: Voidbreaker's Veil
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 251085, source = "Windrunner Spire" },  -- Shoulders: Mantle of Dark Devotion
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 250063, source = "Tier Set" },  -- Chest: Voidbreaker's Robe
            { itemID = 239648, source = "Crafting" },  -- Wrist: Martyr's Bindings
            { itemID = 250061, source = "Tier Set" },  -- Gloves: Voidbreaker's Gloves
            { itemID = 250057, source = "The Catalyst" },  -- Belt: Voidbreaker's Sage Cord
            { itemID = 250059, source = "Tier Set" },  -- Legs: Voidbreaker's Britches
            { itemID = 249373, source = "Chimaerus" },  -- Boots: Dream-Scorched Striders
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249346, source = "Vaelgor & Ezzorak" },  -- Trinket: Vaelgor's Final Stare
        },
        ["M+ BiS"] = {
            { itemID = 245770, source = "Inscription" },  -- Weapon: Aln'hara Cane
            { itemID = 250060, source = "Matrix Catalyst" },  -- Helm: Voidbreaker's Veil
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 251085, source = "Windrunner Spire" },  -- Shoulder: Mantle of Dark Devotion
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 250063, source = "Matrix Catalyst" },  -- Chest: Voidbreaker's Robe
            { itemID = 239648, source = "Tailoring" },  -- Bracers: Martyr's Bindings
            { itemID = 250061, source = "Matrix Catalyst" },  -- Gloves: Voidbreaker's Gloves
            { itemID = 250057, source = "Matrix Catalyst" },  -- Belt: Voidbreaker's Sage Cord
            { itemID = 250059, source = "Matrix Catalyst" },  -- Legs: Voidbreaker's Britches
            { itemID = 133489, source = "Pit of Saron" },  -- Boots: Ice-Steeped Sandals
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #1: Emberwing Feather
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #2: Heart of Wind
        },
    },
    ["MONK_BREWMASTER"] = {  -- updated: 2026/03/17
        ["Overall BiS"] = {
            { itemID = 249302, source = "Vorasius" },  -- Weapon (2h): Inescapable Reach
            { itemID = 251207, source = "Nexus Point Xenas    Maisara Caverns" },  -- Weapons (1h): Dreadflail Bludgeon     Soulblight Cleaver
            { itemID = 250015, source = "Catalyst|Raid|Vault" },  -- Head: Fearsome Visage of Ra-den's Chosen
            { itemID = 240950, source = "Jewelcrafting" },  -- Neck: Masterwork Sin'dorei Amulet(With  Thalassian Missive of the Quickblade  and  Stabilizing Gemstone Bandolier )
            { itemID = 250013, source = "Catalyst|Raid|Vault" },  -- Shoulders: Aurastones of Ra-den's Chosen
            { itemID = 249335, source = "Imperator Averzian" },  -- Cloak: Imperator's Banner
            { itemID = 250018, source = "Catalyst|Raid|Vault" },  -- Chest: Battle Garb of Ra-den's Chosen
            { itemID = 250011, source = "Catalyst" },  -- Wrist: Strikeguards of Ra-den's Chosen
            { itemID = 250016, source = "Catalyst|Raid|Vault" },  -- Gloves: Thunderfists of Ra-den's Chosen
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 151314, source = "Seat of the Triumvirate" },  -- Legs: Shifting Stalker Hide Pants
            { itemID = 151317, source = "Seat of the Triumvirate" },  -- Boots: Footpads of Seeping Dread
            { itemID = 249336, source = "Vorasius" },  -- Ring 1: Signet of the Starved Beast
            { itemID = 251513, source = "Jewelcrafting" },  -- Ring 2: Loa Worshiper's Band
            { itemID = 249806, source = "Belo'ren" },  -- Trinket (Damage): Radiant Plume
            { itemID = 249343, source = "Chimaerus" },  -- Trinket (Damage): Gaze of the Alnseer
            { itemID = 249339, source = "Vaelgor & Ezzorak" },  -- Trinket (Defense): Gloom-Spattered Dreadscale
            { itemID = 151312, source = "Seat of the Triumvirate" },  -- Trinket (Defense): Ampoule of Pure Void
        },
        ["M+ BiS"] = {
            { itemID = 250015, source = "Matrix Catalyst" },  -- Head: Fearsome Visage of Ra-den's Chosen
            { itemID = 240950, source = "Jewelcrafting (see note)" },  -- Neck: Masterwork Sin'dorei Amulet
            { itemID = 250013, source = "Matrix Catalyst" },  -- Shoulders: Aurastones of Ra-den's Chosen
            { itemID = 251161, source = "Maisara Caverns" },  -- Cloak: Soulhunter's Mask
            { itemID = 250018, source = "Matrix Catalyst" },  -- Chest: Battle Garb of Ra-den's Chosen
            { itemID = 50264, source = "Pit of Saron" },  -- Wrists: Chewed Leather Wristguards
            { itemID = 250016, source = "Matrix Catalyst" },  -- Gloves: Thunderfists of Ra-den's Chosen
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 151314, source = "Seat of the Triumvirate" },  -- Legs: Shifting Stalker Hide Pants
            { itemID = 151317, source = "Seat of the Triumvirate" },  -- Boots: Footpads of Seeping Dread
            { itemID = 151308, source = "Seat of the Triumvirate" },  -- Ring 1: Eredath Seal of Nobility
            { itemID = 251513, source = "Jewelcrafting" },  -- Ring 2: Loa Worshiper's Band
            { itemID = 193723, source = "Algeth'ar Academy" },  -- Weapon (2h): Obsidian Goaltending Spire
            { itemID = 251207, source = "Nexus-Point Xenas" },  -- Weapons (Dual Wield): Dreadflail Bludgeon
            { itemID = 252420, source = "Skyreach" },  -- Trinkets: Solarflare Prism
        },
    },
    ["MONK_MISTWEAVER"] = {  -- updated: 2026/04/10
        ["Overall BiS"] = {
            { itemID = 258050, source = "Skyreach" },  -- Weapon: Arcanic of the High Sage
            { itemID = 249276, source = "Vorasius (Raid)" },  -- Offhand: Grimoire of the Eternal Light
            { itemID = 250015, source = "Catalyst via  Mask of Darkest Intent" },  -- Head: Fearsome Visage of Ra-den's Chosen
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249333, source = "Lightblinded Vanguard (Raid)" },  -- Shoulders: Blooming Barklight Spaulders
            { itemID = 260312, source = "Magister's Terrace" },  -- Cape: Defiant Defender's Drape
            { itemID = 250018, source = "Raid | Catalyst | Vault" },  -- Chest: Battle Garb of Ra-den's Chosen
            { itemID = 249327, source = "Vorasius (Raid)" },  -- Bracers: Void-Skinned Bracers
            { itemID = 250016, source = "Raid | Catalyst | Vault" },  -- Gloves: Thunderfists of Ra-den's Chosen
            { itemID = 249374, source = "Chimaerus (Raid)" },  -- Belt: Scorn-Scarred Shul'ka's Belt
            { itemID = 250014, source = "Raid | Catalyst | Vault" },  -- Legs: Swiftsweepers of Ra-den's Chosen
            { itemID = 250017, source = "Catalyst" },  -- Boots: Storm Crashers of Ra-den's Chosen
            { itemID = 249920, source = "Midnight Falls (Raid)" },  -- Ring: Eye of Midnight
            { itemID = 49812, source = "Pit of Saron" },  -- Ring: Purloined Wedding Ring
            { itemID = 249808, source = "Lightblinded Vanguard (Raid)" },  -- Trinket: Litany of Lightblind Wrath
            { itemID = 249343, source = "Chimaerus (Raid)" },  -- Trinket: Gaze of the Alnseer
        },
        ["M+ BiS"] = {
            { itemID = 258050, source = "Skyreach" },  -- Weapon: Arcanic of the High Sage
            { itemID = 193709, source = "Algeth'ar Academy" },  -- Offhand: Vexamus' Expulsion Rod
            { itemID = 151336, source = "Seat of the Triumvirate" },  -- Helm: Voidlashed Hood
            { itemID = 251096, source = "Windrunner Spire" },  -- Neck: Pendant of Aching Grief
            { itemID = 250013, source = "Matrix Catalyst" },  -- Shoulder: Aurastones of Ra-den's Chosen
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250018, source = "Matrix Catalyst" },  -- Chest: Battle Garb of Ra-den's Chosen
            { itemID = 244576, source = "Crafted by Leatherworking" },  -- Bracers: Silvermoon Agent's Deflectors
            { itemID = 250016, source = "Matrix Catalyst" },  -- Gloves: Thunderfists of Ra-den's Chosen
            { itemID = 251166, source = "Maisara Caverns" },  -- Belt: Falconer's Cinch
            { itemID = 250014, source = "Matrix Catalyst" },  -- Legs: Swiftsweepers of Ra-den's Chosen
            { itemID = 251210, source = "Nexus-Point Xenas" },  -- Boots: Eclipse Espadrilles
            { itemID = 151308, source = "Seat of the Triumvirate" },  -- Ring #1: Eredath Seal of Nobility
            { itemID = 151311, source = "Seat of the Triumvirate" },  -- Ring #2: Band of the Triumvirate
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #2: Emberwing Feather
        },
    },
    ["MONK_WINDWALKER"] = {  -- updated: 2026/03/15
        ["Overall BiS"] = {
            { itemID = 250015, source = "Tier Set" },  -- Head: Fearsome Visage of Ra-den's Chosen
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250013, source = "Tier Set" },  -- Shoulder: Aurastones of Ra-den's Chosen
            { itemID = 250010, source = "The Catalyst" },  -- Cloak: Windwrap of Ra-den's Chosen
            { itemID = 250018, source = "Tier Set" },  -- Chest: Battle Garb of Ra-den's Chosen
            { itemID = 249327, source = "Vorasius" },  -- Wrist: Void-Skinned Bracers
            { itemID = 249321, source = "Vaelgor & Ezzorak" },  -- Hands: Vaelgor's Fearsome Grasp
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 250014, source = "Tier Set" },  -- Legs: Swiftsweepers of Ra-den's Chosen
            { itemID = 250017, source = "The Catalyst" },  -- Feet: Storm Crashers of Ra-den's Chosen
            { itemID = 251513, source = "Crafting" },  -- Ring: Loa Worshiper's Band
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 251162, source = "Maisara Caverns" },  -- 2H Weapon: Traitor's Talon
            { itemID = 260423, source = "Crown of the Cosmos" },  -- 1H Weapon: Arator's Swift Remembrance
            { itemID = 237845, source = "Crafting" },  -- 1H Weapon: Bloomforged Claw
            { itemID = 249343, source = "Chimaerus" },  -- Trinket 1: Gaze of the Alnseer
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket 2: Algeth'ar Puzzle Box
        },
        ["M+ BiS"] = {
            { itemID = 251162, source = "Maisara Caverns" },  -- 2H Weapon: Traitor's Talon
            { itemID = 251122, source = "Magister's Terrace" },  -- 1H Weapon: Shadowslash Slicer
            { itemID = 237845, source = "Blacksmithing" },  -- 1H Weapon: Bloomforged Claw
            { itemID = 250015, source = "Matrix Catalyst" },  -- Head: Fearsome Visage of Ra-den's Chosen
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250013, source = "Matrix Catalyst" },  -- Shoulder: Aurastones of Ra-den's Chosen
            { itemID = 250010, source = "Matrix Catalyst" },  -- Cloak: Windwrap of Ra-den's Chosen
            { itemID = 250018, source = "Matrix Catalyst" },  -- Chest: Battle Garb of Ra-den's Chosen
            { itemID = 193714, source = "Algeth'ar Academy" },  -- Wrist: Frenzyroot Cuffs
            { itemID = 151318, source = "Seat of the Triumvirate" },  -- Hands: Gloves of the Dark Shroud
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 250014, source = "Matrix Catalyst" },  -- Legs: Swiftsweepers of Ra-den's Chosen
            { itemID = 250017, source = "Matrix Catalyst" },  -- Feet: Storm Crashers of Ra-den's Chosen
            { itemID = 251513, source = "Jewelcrafting" },  -- Ring: Loa Worshiper's Band
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring: Omission of Light
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket 1: Heart of Wind
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket 2: Algeth'ar Puzzle Box
        },
    },
    ["PALADIN_HOLY"] = {  -- updated: 2026/03/23
        ["Overall BiS"] = {
            { itemID = 193710, source = "Algeth'ar Academy" },  -- Weapon: Spellboon Saber
            { itemID = 258049, source = "Skyreach" },  -- Shield: Viryx's Indomitable Bulwark
            { itemID = 249961, source = "Lightblinded Vanguard" },  -- Head: Luminant Verdict's Unwavering Gaze
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 249959, source = "Fallen-King Salhadaar" },  -- Shoulders: Luminant Verdict's Providence Watch
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 249964, source = "Chimaerus" },  -- Chest: Luminant Verdict's Divine Warplate
            { itemID = 263193, source = "Maisara Caverns" },  -- Wrist: Trollhunter's Bands
            { itemID = 249962, source = "Vorasius" },  -- Gloves: Luminant Verdict's Gauntlets
            { itemID = 249331, source = "Vaelgor & Ezzorak" },  -- Belt: Ezzorak's Gloombind
            { itemID = 249915, source = "Midnight Falls" },  -- Legs: Extinction Guards
            { itemID = 249332, source = "Vorasius" },  -- Boots: Parasite Stompers
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249809, source = "Fallen-King Salhadaar" },  -- Trinket: Locus-Walker's Ribbon
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
        },
        ["M+ BiS"] = {
            { itemID = 193710, source = "Algeth'ar Academy" },  -- Mainhand Weapon: Spellboon Saber
            { itemID = 258049, source = "Skyreach" },  -- Shield: Viryx's Indomitable Bulwark
            { itemID = 249961, source = "Matrix Catalyst" },  -- Helm: Luminant Verdict's Unwavering Gaze
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249959, source = "Matrix Catalyst" },  -- Shoulder: Luminant Verdict's Providence Watch
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249964, source = "Matrix Catalyst" },  -- Chest: Luminant Verdict's Divine Warplate
            { itemID = 237834, source = "Crafted by Blacksmithing" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 249962, source = "Matrix Catalyst" },  -- Gloves: Luminant Verdict's Gauntlets
            { itemID = 151327, source = "Seat of the Triumvirate" },  -- Belt: Girdle of the Shadowguard
            { itemID = 251118, source = "Magister's Terrace" },  -- Legs: Legplates of Lingering Dusk
            { itemID = 251107, source = "Magister's Terrace" },  -- Boots: Oathsworn Stompers
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring #1: Bifurcation Band
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #2: Emberwing Feather
        },
    },
    ["PALADIN_PROTECTION"] = {  -- updated: 2026/03/19
        ["Overall BiS"] = {
            { itemID = 249295, source = "Crown of the Cosmos" },  -- Weapon: Turalyon's False Echo
            { itemID = 249921, source = "Belo'ren" },  -- Offhand: Thalassian Dawnguard
            { itemID = 249961, source = "Tier Set" },  -- Head: Luminant Verdict's Unwavering Gaze
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 249959, source = "Tier Set" },  -- Shoulders: Luminant Verdict's Providence Watch
            { itemID = 249370, source = "Vaelgor & Ezzorak" },  -- Cloak: Draconic Nullcape
            { itemID = 249964, source = "Tier Set" },  -- Chest: Luminant Verdict's Divine Warplate
            { itemID = 249326, source = "Imperator Averzian" },  -- Wrist: Light's March Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 249331, source = "Vaelgor & Ezzorak" },  -- Belt: Ezzorak's Gloombind
            { itemID = 249960, source = "Tier Set" },  -- Legs: Luminant Verdict's Greaves
            { itemID = 249381, source = "Chimaerus" },  -- Boots: Greaves of the Unformed
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 151311, source = "Seat of the Triumvirate" },  -- Ring: Band of the Triumvirate
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249342, source = "Vorasius" },  -- Trinket: Heart of Ancient Hunger
        },
        ["M+ BiS"] = {
            { itemID = 193711, source = "Algeth'ar Academy" },  -- Weapon: Spellbane Cutlass
            { itemID = 251105, source = "Magister's Terrace" },  -- Shield: Ward of the Spellbreaker
            { itemID = 249961, source = "Matrix Catalyst" },  -- Helm: Luminant Verdict's Unwavering Gaze
            { itemID = 251096, source = "Windrunner Spire" },  -- Neck: Pendant of Aching Grief
            { itemID = 249959, source = "Matrix Catalyst" },  -- Shoulder: Luminant Verdict's Providence Watch
            { itemID = 49823, source = "Pit of Saron" },  -- Cloak: Cloak of the Fallen Cardinal
            { itemID = 249964, source = "Matrix Catalyst" },  -- Chest: Luminant Verdict's Divine Warplate
            { itemID = 237834, source = "Crafted by Blacksmithing" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 251112, source = "Magister's Terrace" },  -- Belt: Shadowsplit Girdle
            { itemID = 249960, source = "Matrix Catalyst" },  -- Legs: Luminant Verdict's Greaves
            { itemID = 251169, source = "Maisara Caverns" },  -- Boots: Footwraps of Ill-Fate
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 251513, source = "Crafted by Jewelcrafting" },  -- Ring #2: Loa Worshiper's Band
            { itemID = 252420, source = "Skyreach" },  -- Trinket #1: Solarflare Prism
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #2: Algeth'ar Puzzle Box
        },
    },
    ["PALADIN_RETRIBUTION"] = {  -- updated: 2026/03/17
        ["Overall BiS"] = {
            { itemID = 249277, source = "Lightblinded Vanguard" },  -- Weapon: Bellamy's Final Judgement
            { itemID = 249961, source = "Tier Set" },  -- Head: Luminant Verdict's Unwavering Gaze
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 249959, source = "Tier Set" },  -- Shoulders: Luminant Verdict's Providence Watch
            { itemID = 239656, source = "Crafting/Misc" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249964, source = "Tier Set" },  -- Chest: Luminant Verdict's Divine Warplate
            { itemID = 237834, source = "Crafting/Misc" },  -- Wrist: Spellbreaker's Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 249380, source = "Crown of the Cosmos" },  -- Belt: Hate-Tied Waistchain
            { itemID = 249960, source = "Tier Set" },  -- Legs: Luminant Verdict's Greaves
            { itemID = 249381, source = "Chimaerus" },  -- Boots: Greaves of the Unformed
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 260235, source = "Belo'ren" },  -- Trinket: Umbral Plume
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
        },
        ["M+ BiS"] = {
            { itemID = 251168, source = "Maisara Caverns" },  -- Weapon: Liferipper's Cutlass
            { itemID = 249961, source = "Matrix Catalyst" },  -- Helm: Luminant Verdict's Unwavering Gaze
            { itemID = 50228, source = "Midnight Falls in March on Quel'Danas" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249959, source = "Matrix Catalyst" },  -- Shoulder: Luminant Verdict's Providence Watch
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249964, source = "Matrix Catalyst" },  -- Chest: Luminant Verdict's Divine Warplate
            { itemID = 237834, source = "Crafted by Blacksmithing" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 151327, source = "Seat of the Triumvirate" },  -- Belt: Girdle of the Shadowguard
            { itemID = 249960, source = "Matrix Catalyst" },  -- Legs: Luminant Verdict's Greaves
            { itemID = 251107, source = "Magister's Terrace" },  -- Boots: Oathsworn Stompers
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 252420, source = "Skyreach" },  -- Trinket #1: Solarflare Prism
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #2: Algeth'ar Puzzle Box
        },
    },
    ["PRIEST_DISCIPLINE"] = {  -- updated: 2026/03/19
        ["Overall BiS"] = {
            { itemID = 250051, source = "Raid | Catalyst | Vault" },  -- Helm: Blind Oath's Winged Crest
            { itemID = 249368, source = "Crown of the Cosmos (Raid)" },  -- Neck: Eternal Voidsong Chain
            { itemID = 250049, source = "Raid | Catalyst | Vault" },  -- Shoulders: Blind Oath's Seraphguards
            { itemID = 249370, source = "Vaelgor & Ezzorak (Raid)" },  -- Cape: Draconic Nullcape
            { itemID = 249912, source = "Midnight Falls (Raid)" },  -- Chest: Robes of Endless Oblivion
            { itemID = 249315, source = "Vorasius(Raid)" },  -- Bracers: Voracious Wristwraps
            { itemID = 250052, source = "Raid | Catalyst | Vault" },  -- Gloves: Blind Oath's Touch
            { itemID = 239664, source = "Crafting/Misc" },  -- Belt: Arcanoweave Cord
            { itemID = 250050, source = "Raid | Catalyst | Vault" },  -- Legs: Blind Oath's Leggings
            { itemID = 258584, source = "Skyreach" },  -- Boots: Lightbinder Treads
            { itemID = 249920, source = "Midnight Falls (Raid)" },  -- Ring: Eye of Midnight
            { itemID = 251093, source = "Nexus Point Xenas" },  -- Ring: Omission of Light
            { itemID = 249808, source = "War Chaplain Senn (Raid)" },  -- Trinkets: Litany of Lightblind Wrath
            { itemID = 249346, source = "Vaelgor & Ezzorak (Raid)" },  -- Trinkets: Vaelgor's Final Stare
            { itemID = 249283, source = "Belo'ren (Raid)" },  -- 1h Weapon: Belo'melorn, the Shattered Talon
            { itemID = 245769, source = "Crafting/Misc" },  -- Offhand: Aln'hara Lantern
        },
        ["M+ BiS"] = {
            { itemID = 251178, source = "Maisara Caverns" },  -- Weapon: Ceremonial Hexblade
            { itemID = 245769, source = "Crafted by Inscription" },  -- Offhand: Aln'hara Lantern
            { itemID = 250051, source = "Matrix Catalyst" },  -- Helm: Blind Oath's Winged Crest
            { itemID = 151309, source = "Seat of the Triumvirate" },  -- Neck: Necklace of the Twisting Void
            { itemID = 251213, source = "Nexus-Point Xenas" },  -- Shoulder: Nysarra's Mantle
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 250054, source = "Matrix Catalyst" },  -- Chest: Blind Oath's Raiment
            { itemID = 133493, source = "Pit of Saron" },  -- Bracers: Wristguards of Subterranean Moss
            { itemID = 250052, source = "Matrix Catalyst" },  -- Gloves: Blind Oath's Touch
            { itemID = 239664, source = "Crafted by Tailoring" },  -- Belt: Arcanoweave Cord
            { itemID = 250050, source = "Matrix Catalyst" },  -- Legs: Blind Oath's Leggings
            { itemID = 258584, source = "Skyreach" },  -- Boots: Lightbinder Treads
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 151311, source = "Seat of the Triumvirate" },  -- Ring #2: Band of the Triumvirate
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 193718, source = "Algeth'ar Academy" },  -- Trinket #2: Emerald Coach's Whistle
        },
    },
    ["PRIEST_HOLY"] = {  -- updated: 2026/03/21
        ["Overall BiS"] = {
            { itemID = 250051, source = "Raid | Catalyst | Vault" },  -- Helm: Blind Oath's Winged Crest
            { itemID = 250247, source = "Midnight Falls (Raid)" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250049, source = "Raid | Catalyst | Vault" },  -- Shoulders: Blind Oath's Seraphguards
            { itemID = 249335, source = "Imperator Averzian (Raid)" },  -- Cape: Imperator's Banner
            { itemID = 249912, source = "Midnight Falls (Raid)" },  -- Chest: Robes of Endless Oblivion
            { itemID = 250047, source = "Raid | Catalyst | Vault" },  -- Bracers: Blind Oath's Wraps
            { itemID = 250052, source = "Raid | Catalyst | Vault" },  -- Gloves: Blind Oath's Touch
            { itemID = 239664, source = "Crafting/Misc" },  -- Belt: Arcanoweave Cord
            { itemID = 250050, source = "Raid | Catalyst | Vault" },  -- Legs: Blind Oath's Leggings
            { itemID = 249373, source = "Chimaerus" },  -- Boots: Dream-Scorched Striders
            { itemID = 249336, source = "Vorasius(Raid)" },  -- Ring: Signet of the Starved Beast
            { itemID = 249919, source = "Belo'ren (Raid)" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249809, source = "Crown of the Cosmos (Raid)" },  -- Trinkets: Locus-Walker's Ribbon
            { itemID = 249808, source = "War Chaplain Senn (Raid)" },  -- Trinkets: Litany of Lightblind Wrath
            { itemID = 249293, source = "Imperator Averzian(Raid)" },  -- 1h Weapon: Weight of Command
            { itemID = 245769, source = "Crafting/Misc" },  -- Offhand: Aln'hara Lantern
        },
        ["M+ BiS"] = {
            { itemID = 245770, source = "Crafted with Inscription" },  -- Weapon: Aln'hara Cane
            { itemID = 250051, source = "Matrix Catalyst" },  -- Helm: Blind Oath's Winged Crest
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250049, source = "Matrix Catalyst" },  -- Shoulders: Blind Oath's Seraphguards
            { itemID = 49823, source = "Pit of Saron" },  -- Cape: Cloak of the Fallen Cardinal
            { itemID = 250054, source = "Matrix Catalyst" },  -- Chest: Blind Oath's Raiment
            { itemID = 258580, source = "Skyreach" },  -- Bracers: Bracers of Blazing Light
            { itemID = 250052, source = "Matrix Catalyst" },  -- Gloves: Blind Oath's Touch
            { itemID = 239664, source = "Crafted with Tailoring" },  -- Belt: Arcanoweave Cord
            { itemID = 250050, source = "Matrix Catalyst" },  -- Legs: Blind Oath's Leggings
            { itemID = 251167, source = "Maisara Caverns" },  -- Boots: Nightprey Stalkers
            { itemID = 151308, source = "Seat of the Triumvirate" },  -- Ring: Eredath Seal of Nobility
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 193718, source = "Algeth'ar Academy" },  -- Trinkets: Emerald Coach's Whistle
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinkets: Heart of Wind
        },
    },
    ["PRIEST_SHADOW"] = {  -- updated: 2026/03/20
        ["Overall BiS"] = {
            { itemID = 250051, source = "Raid | Catalyst | Vault" },  -- Helm: Blind Oath's Winged Crest
            { itemID = 250247, source = "Midnight Falls (Raid)" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 250049, source = "Raid | Catalyst | Vault" },  -- Shoulders: Blind Oath's Seraphguards
            { itemID = 249370, source = "Vaelgor & Ezzorak (Raid)" },  -- Cape: Draconic Nullcape
            { itemID = 250054, source = "Raid | Catalyst | Vault" },  -- Chest: Blind Oath's Raiment
            { itemID = 251108, source = "Magister's Terrace" },  -- Bracers: Wraps of Watchful Wrath
            { itemID = 250052, source = "Raid | Catalyst | Vault" },  -- Gloves: Blind Oath's Touch
            { itemID = 249376, source = "Belo'ren (Raid)" },  -- Belt: Whisper-Inscribed Sash
            { itemID = 250050, source = "Raid | Catalyst | Vault" },  -- Legs: Blind Oath's Leggings
            { itemID = 249373, source = "Chimaerus" },  -- Boots: Dream-Scorched Striders
            { itemID = 249920, source = "Midnight Falls (Raid)" },  -- Ring: Eye of Midnight
            { itemID = 249369, source = "Lightblinded Vanguard (Raid)" },  -- Ring: Bond of Light
            { itemID = 249343, source = "Chimaerus (Raid)" },  -- Trinkets: Gaze of the Alnseer
            { itemID = 249346, source = "Vaelgor & Ezzorak (Raid)" },  -- Trinkets: Vaelgor's Final Stare
            { itemID = 249283, source = "Belo'ren (Raid)" },  -- 1h Weapon: Belo'melorn, the Shattered Talon
            { itemID = 249922, source = "Chimaerus (Raid)" },  -- Offhand: Tome of Alnscorned Regret
        },
        ["M+ BiS"] = {
            { itemID = 251111, source = "Magister's Terrace" },  -- Weapons: Splitshroud Stinger
            { itemID = 250051, source = "Matrix Catalyst" },  -- Head: Blind Oath's Winged Crest
            { itemID = 151309, source = "Seat of the Triumvirate" },  -- Neck: Necklace of the Twisting Void
            { itemID = 250049, source = "Matrix Catalyst" },  -- Shoulder: Blind Oath's Seraphguards
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 250054, source = "Matrix Catalyst" },  -- Chest: Blind Oath's Raiment
            { itemID = 151305, source = "Seat of the Triumvirate" },  -- Wrist: Entropic Wristwraps
            { itemID = 251172, source = "Maisara Caverns" },  -- Hands: Vilehex Bonds
            { itemID = 151302, source = "Seat of the Triumvirate" },  -- Waist: Cord of Unraveling Reality
            { itemID = 250050, source = "Matrix Catalyst" },  -- Legs: Blind Oath's Leggings
            { itemID = 258584, source = "Skyreach" },  -- Feet: Lightbinder Treads
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Rings: Omission of Light
            { itemID = 250223, source = "Maisara Caverns" },  -- Top Trinkets: Soulcatcher's Charm
        },
    },
    ["ROGUE_ASSASSINATION"] = {  -- updated: 2026/03/02
        ["Overall BiS"] = {
            { itemID = 249925, source = "Vorasius" },  -- Weapon: Hungering Victory
            { itemID = 237837, source = "Crafting" },  -- Offhand: Farstrider's Mercy
            { itemID = 250006, source = "Tier Set" },  -- Head: Masquerade of the Grim Jest
            { itemID = 249337, source = "Fallen-King Salhadaar" },  -- Neck: Ribbon of Coiled Malice
            { itemID = 250004, source = "Tier Set" },  -- Shoulders: Venom Casks of the Grim Jest
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 250009, source = "Tier Set" },  -- Chest: Fantastic Finery of the Grim Jest
            { itemID = 244576, source = "Crafting" },  -- Wrist: Silvermoon Agent's Deflectors
            { itemID = 250007, source = "Tier Set" },  -- Gloves: Sleight of Hand of the Grim Jest
            { itemID = 249374, source = "Chimaerus" },  -- Belt: Scorn-Scarred Shul'ka's Belt
            { itemID = 251087, source = "Windrunner Spire" },  -- Legs: Legwraps of Lingering Legacies
            { itemID = 249382, source = "Crown of the Cosmos" },  -- Boots: Canopy Walker's Footwraps
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
        },
        ["M+ BiS"] = {
            { itemID = 258436, source = "Skyreach" },  -- Mainhand Weapon: Edge of the Burning Sun
            { itemID = 237837, source = "Crafted by Blacksmithing" },  -- Offhand Weapon: Farstrider's Mercy
            { itemID = 250006, source = "Matrix Catalyst" },  -- Helm: Masquerade of the Grim Jest
            { itemID = 151309, source = "Seat of the Triumvirate" },  -- Neck: Necklace of the Twisting Void
            { itemID = 250004, source = "Matrix Catalyst" },  -- Shoulder: Venom Casks of the Grim Jest
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 250009, source = "Matrix Catalyst" },  -- Chest: Fantastic Finery of the Grim Jest
            { itemID = 244576, source = "Crafted by Leatherworking" },  -- Bracers: Silvermoon Agent's Deflectors
            { itemID = 250007, source = "Matrix Catalyst" },  -- Gloves: Sleight of Hand of the Grim Jest
            { itemID = 251082, source = "Windrunner Spire" },  -- Belt: Snapvine Cinch
            { itemID = 251087, source = "Windrunner Spire" },  -- Legs: Legwraps of Lingering Legacies
            { itemID = 258577, source = "Skyreach" },  -- Boots: Boots of Burning Focus
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["ROGUE_OUTLAW"] = {  -- updated: 2026/02/25
        ["Overall BiS"] = {
            { itemID = 260423, source = "Crown of the Cosmos" },  -- Weapon: Arator's Swift Remembrance
            { itemID = 133491, source = "Pit of Saron" },  -- Offhand: Krick's Beetle Stabber
            { itemID = 151336, source = "Seat of the Triumvirate" },  -- Head: Voidlashed Hood
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250004, source = "Tier Set" },  -- Shoulders: Venom Casks of the Grim Jest
            { itemID = 249335, source = "Imperator Averzian" },  -- Cloak: Imperator's Banner
            { itemID = 250009, source = "Tier Set" },  -- Chest: Fantastic Finery of the Grim Jest
            { itemID = 50264, source = "Pit of Saron" },  -- Wrist: Chewed Leather Wristguards
            { itemID = 250007, source = "Tier Set" },  -- Gloves: Sleight of Hand of the Grim Jest
            { itemID = 249374, source = "Chimaerus" },  -- Belt: Scorn-Scarred Shul'ka's Belt
            { itemID = 250005, source = "Tier Set" },  -- Legs: Blade Holsters of the Grim Jest
            { itemID = 244569, source = "Crafting" },  -- Boots: Silvermoon Agent's Sneakers
            { itemID = 249336, source = "Vorasius" },  -- Ring: Signet of the Starved Beast
            { itemID = 240949, source = "Crafting" },  -- Ring: Masterwork Sin'dorei Band
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 260235, source = "Belo'ren" },  -- Trinket: Umbral Plume
        },
        ["M+ BiS"] = {
            { itemID = 251207, source = "Nexus-Point Xenas" },  -- Mainhand Weapon: Dreadflail Bludgeon
            { itemID = 133491, source = "Pit of Saron" },  -- Offhand Weapon: Krick's Beetle Stabber
            { itemID = 151336, source = "Seat of the Triumvirate" },  -- Helm: Voidlashed Hood
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250004, source = "Matrix Catalyst" },  -- Shoulder: Venom Casks of the Grim Jest
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 250009, source = "Matrix Catalyst" },  -- Chest: Fantastic Finery of the Grim Jest
            { itemID = 50264, source = "Pit of Saron" },  -- Bracers: Chewed Leather Wristguards
            { itemID = 250007, source = "Matrix Catalyst" },  -- Gloves: Sleight of Hand of the Grim Jest
            { itemID = 251166, source = "Maisara Caverns" },  -- Belt: Falconer's Cinch
            { itemID = 250005, source = "Matrix Catalyst" },  -- Legs: Blade Holsters of the Grim Jest
            { itemID = 244569, source = "Crafted by Leatherworking" },  -- Boots: Silvermoon Agent's Sneakers
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #1: Occlusion of Void
            { itemID = 240949, source = "Crafted by Jewelcrafting" },  -- Ring #2: Masterwork Sin'dorei Band
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["ROGUE_SUBTLETY"] = {  -- updated: 2026/03/26
        ["Overall BiS"] = {
            { itemID = 250006, source = "Tier Set" },  -- Head: Masquerade of the Grim Jest
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 250004, source = "Tier Set" },  -- Shoulders: Venom Casks of the Grim Jest
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 250009, source = "Tier Set" },  -- Chest: Fantastic Finery of the Grim Jest
            { itemID = 249327, source = "Vorasius" },  -- Wrist: Void-Skinned Bracers
            { itemID = 250007, source = "Tier Set" },  -- Gloves: Sleight of Hand of the Grim Jest
            { itemID = 244573, source = "Crafting" },  -- Belt: Silvermoon Agent's Utility Belt
            { itemID = 49817, source = "Pit of Saron" },  -- Legs: Shaggy Wyrmleather Leggings
            { itemID = 258577, source = "Skyreach" },  -- Boots: Boots of Burning Focus
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring: Bifurcation Band
            { itemID = 249344, source = "Imperator Averzian" },  -- Trinket: Light Company Guidon
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249925, source = "Vorasius" },  -- Weapon: Hungering Victory
            { itemID = 237837, source = "Crafting" },  -- Offhand: Farstrider's Mercy
        },
        ["M+ BiS"] = {
            { itemID = 258436, source = "Skyreach" },  -- Mainhand Weapon: Edge of the Burning Sun
            { itemID = 250006, source = "Matrix Catalyst" },  -- Helm: Masquerade of the Grim Jest
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 250004, source = "Matrix Catalyst" },  -- Shoulder: Venom Casks of the Grim Jest
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 250009, source = "Matrix Catalyst" },  -- Chest: Fantastic Finery of the Grim Jest
            { itemID = 193714, source = "Algeth'ar Academy" },  -- Bracers: Frenzyroot Cuffs
            { itemID = 250007, source = "Matrix Catalyst" },  -- Gloves: Sleight of Hand of the Grim Jest
            { itemID = 49806, source = "Pit of Saron" },  -- Belt: Flayer's Black Belt
            { itemID = 49817, source = "Pit of Saron" },  -- Legs: Shaggy Wyrmleather Leggings
            { itemID = 258577, source = "Skyreach" },  -- Boots: Boots of Burning Focus
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring #1: Platinum Star Band
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring #2: Bifurcation Band
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #1: Emberwing Feather
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["SHAMAN_ELEMENTAL"] = {  -- updated: 2026/03/01
        ["Overall BiS"] = {
            { itemID = 251083, source = "Windrunner Spire" },  -- Weapon: Excavating Cudgel
            { itemID = 251105, source = "Magister's Terrace" },  -- Offhand: Ward of the Spellbreaker
            { itemID = 249979, source = "Tier Set" },  -- Head: Locus of the Primal Core
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 249977, source = "Tier Set" },  -- Shoulders: Tempests of the Primal Core
            { itemID = 249974, source = "Catalyst" },  -- Cloak: Guardian of the Primal Core
            { itemID = 249982, source = "Tier Set" },  -- Chest: Embrace of the Primal Core
            { itemID = 249304, source = "Fallen-King Salhadaar" },  -- Wrist: Fallen King's Cuffs
            { itemID = 249980, source = "Tier Set" },  -- Gloves: Earthgrips of the Primal Core
            { itemID = 244611, source = "Crafting" },  -- Belt: World Tender's Barkclasp
            { itemID = 251215, source = "Nexus Point Xenas" },  -- Legs: Greaves of the Divine Guile
            { itemID = 244610, source = "Crafting" },  -- Boots: World Tender's Rootslippers
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 249919, source = "Belo'ren" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket: Emberwing Feather
        },
        ["M+ BiS"] = {
            { itemID = 251083, source = "Windrunner Spire" },  -- Weapon: Excavating Cudgel
            { itemID = 251105, source = "Magister's Terrace" },  -- Off-hand: Ward of the Spellbreaker
            { itemID = 249979, source = "Matrix Catalyst" },  -- Helm: Locus of the Primal Core
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249977, source = "Matrix Catalyst" },  -- Shoulder: Tempests of the Primal Core
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 249982, source = "Matrix Catalyst" },  -- Chest: Embrace of the Primal Core
            { itemID = 251079, source = "Windrunner Spire" },  -- Bracers: Amberfrond Bracers
            { itemID = 151321, source = "Seat of the Triumvirate" },  -- Bracers alternative: Darkfang Scale Wristguards
            { itemID = 249980, source = "Matrix Catalyst" },  -- Gloves: Earthgrips of the Primal Core
            { itemID = 244611, source = "Crafted by Leatherworking" },  -- Belt: World Tender's Barkclasp
            { itemID = 251215, source = "Nexus-Point Xenas" },  -- Legs: Greaves of the Divine Guile
            { itemID = 244610, source = "Crafted by Leatherworking" },  -- Boots: World Tender's Rootslippers
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring #1: Platinum Star Band
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring #2: Bifurcation Band
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2 alternative: Omission of Light
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #1: Emberwing Feather
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #2: Heart of Wind
        },
    },
    ["SHAMAN_ENHANCEMENT"] = {  -- updated: 2026/04/02
        ["Overall BiS"] = {
            { itemID = 249287, source = "Vaelgor & Ezzorak" },  -- Main Hand: Clutchmates' Caress
            { itemID = 237850, source = "Blacksmithing" },  -- Off Hand: Farstrider's Chopper
            { itemID = 249979, source = "Tier Set" },  -- Head: Locus of the Primal Core
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 249977, source = "Tier Set" },  -- Shoulders: Tempests of the Primal Core
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249982, source = "Tier Set" },  -- Chest: Embrace of the Primal Core
            { itemID = 249304, source = "Fallen-King Salhadaar" },  -- Wrist: Fallen King's Cuffs
            { itemID = 249980, source = "Tier Set" },  -- Gloves: Earthgrips of the Primal Core
            { itemID = 249976, source = "Catalyst" },  -- Belt: Ceinture of the Primal Core
            { itemID = 249324, source = "Belo'ren" },  -- Legs: Eternal Flame Scaleguards
            { itemID = 251084, source = "Windrunner Spire" },  -- Boots: Whipcoil Sabatons
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring: Omission of Light
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket: Algeth'ar Puzzle Box
        },
        ["M+ BiS"] = {
            { itemID = 258438, source = "Skyreach" },  -- Main Hand: Blazing Sunclaws
            { itemID = 237850, source = "Blacksmithing" },  -- Off Hand: Farstrider's Chopper
            { itemID = 249979, source = "Matrix Catalyst" },  -- Helm: Locus of the Primal Core
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249977, source = "Matrix Catalyst" },  -- Shoulder: Tempests of the Primal Core
            { itemID = 239656, source = "Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249982, source = "Matrix Catalyst" },  -- Chest: Embrace of the Primal Core
            { itemID = 251079, source = "Windrunner Spire" },  -- Bracers: Amberfrond Bracers
            { itemID = 249980, source = "Matrix Catalyst" },  -- Gloves: Earthgrips of the Primal Core
            { itemID = 49810, source = "Pit of Saron" },  -- Belt: Scabrous Zombie Leather Belt
            { itemID = 251215, source = "Nexus-Point Xenas" },  -- Legs: Greaves of the Divine Guile
            { itemID = 251084, source = "Windrunner Spire" },  -- Boots: Whipcoil Sabatons
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 251217, source = "Algeth'ar Academy" },  -- Ring #2: Occlusion of Void
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["SHAMAN_RESTORATION"] = {  -- updated: 2026/03/27
        ["Overall BiS"] = {
            { itemID = 249914, source = "Midnight Falls (Raid)" },  -- Helm: Oblivion Guise
            { itemID = 249337, source = "Fallen-King Salhadaar (Raid)" },  -- Neck: Ribbon of Coiled Malice
            { itemID = 249977, source = "Raid | Catalyst | Vault" },  -- Shoulders: Tempests of the Primal Core
            { itemID = 249974, source = "Catalyst" },  -- Cape: Guardian of the Primal Core
            { itemID = 249982, source = "Raid | Catalyst | Vault" },  -- Chest: Embrace of the Primal Core
            { itemID = 249975, source = "Catalyst" },  -- Bracers: Cuffs of the Primal Core
            { itemID = 249980, source = "Raid | Catalyst | Vault" },  -- Gloves: Earthgrips of the Primal Core
            { itemID = 249303, source = "Lightblinded Vanguard (Raid)" },  -- Belt: Waistcord of the Judged
            { itemID = 249978, source = "Raid | Catalyst | Vault" },  -- Legs: Leggings of the Primal Core
            { itemID = 249320, source = "Imperator Averzian (Raid)" },  -- Boots: Sabatons of Obscurement
            { itemID = 249919, source = "Belo'ren (Raid)" },  -- Ring: Sin'dorei Band of Hope
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 249343, source = "Chimaerus (Raid)" },  -- Trinkets: Gaze of the Alnseer
            { itemID = 264507, source = "The Singularity" },  -- Trinkets: Crucible of Erratic Energies
            { itemID = 249293, source = "Imperator Averzian (Raid)" },  -- 1h Weapon: Weight of Command
            { itemID = 251202, source = "Nexus Point Xenas" },  -- Shield: Reflux Reflector
        },
        ["M+ BiS"] = {
            { itemID = 251178, source = "Maisara Caverns" },  -- Weapon: Ceremonial Hexblade
            { itemID = 258049, source = "Skyreach" },  -- Off-hand: Viryx's Indomitable Bulwark
            { itemID = 258585, source = "Skyreach" },  -- Helm: Sharpeye Gleam
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249977, source = "Matrix Catalyst" },  -- Shoulder: Tempests of the Primal Core
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 249982, source = "Matrix Catalyst" },  -- Chest: Embrace of the Primal Core
            { itemID = 151321, source = "Seat of the Triumvirate" },  -- Bracers: Darkfang Scale Wristguards
            { itemID = 249980, source = "Matrix Catalyst" },  -- Gloves: Earthgrips of the Primal Core
            { itemID = 49810, source = "Pit of Saron" },  -- Belt: Scabrous Zombie Leather Belt
            { itemID = 249978, source = "Matrix Catalyst" },  -- Legs: Leggings of the Primal Core
            { itemID = 258582, source = "Skyreach" },  -- Boots: Rigid Scale Boots
            { itemID = 151308, source = "Seat of the Triumvirate" },  -- Ring #1: Eredath Seal of Nobility
            { itemID = 151311, source = "Seat of the Triumvirate" },  -- Ring #2: Band of the Triumvirate
            { itemID = 193718, source = "Algeth'ar Academy" },  -- Trinket #1: Emerald Coach's Whistle
            { itemID = 250253, source = "Nexus-Point Xenas" },  -- Trinket #2: Whisper of the Duskwraith
        },
    },
    ["WARLOCK_AFFLICTION"] = {  -- updated: 2026/03/14
        ["Overall BiS"] = {
            { itemID = 249283, source = "Belo'ren" },  -- Weapon: Belo'melorn, the Shattered Talon
            { itemID = 249276, source = "Vorasius" },  -- Off-Hand: Grimoire of the Eternal Light
            { itemID = 250042, source = "Tier Set" },  -- Head: Abyssal Immolator's Smoldering Flames
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 251085, source = "Windrunner Spire" },  -- Shoulders: Mantle of Dark Devotion
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250045, source = "Tier Set" },  -- Chest: Abyssal Immolator's Dreadrobe
            { itemID = 239648, source = "Crafted" },  -- Wrist: Martyr's Bindings
            { itemID = 250043, source = "Tier Set" },  -- Gloves: Abyssal Immolator's Grasps
            { itemID = 249376, source = "Belo'ren" },  -- Belt: Whisper-Inscribed Sash
            { itemID = 250041, source = "Tier Set" },  -- Legs: Abyssal Immolator's Pillars
            { itemID = 249305, source = "Vaelgor" },  -- Boots: Slippers of the Midnight Flame
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 251217, source = "Nexus Point Xenas" },  -- Ring: Occlusion of Void
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket: Emberwing Feather
        },
        ["M+ BiS"] = {
            { itemID = 250042, source = "Matrix Catalyst" },  -- Head: Abyssal Immolator's Smoldering Flames
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 251085, source = "Windrunner Spire" },  -- Shoulder: Mantle of Dark Devotion
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250045, source = "Matrix Catalyst" },  -- Chest: Abyssal Immolator's Dreadrobe
            { itemID = 239648, source = "Crafted by Tailoring" },  -- Wrists: Martyr's Bindings
            { itemID = 250043, source = "Matrix Catalyst" },  -- Hands: Abyssal Immolator's Grasps
            { itemID = 251102, source = "Magister's Terrace" },  -- Belt: Clasp of Compliance
            { itemID = 250041, source = "Matrix Catalyst" },  -- Legs: Abyssal Immolator's Pillars
            { itemID = 251167, source = "Maisara Caverns" },  -- Feet: Nightprey Stalkers
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #1: Emberwing Feather
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #2: Heart of Wind
            { itemID = 251111, source = "Magister's Terrace" },  -- Weapon: Splitshroud Stinger
            { itemID = 251094, source = "Windrunner Spire" },  -- Off-Hand: Sigil of the Restless Heart
        },
    },
    ["WARLOCK_DEMONOLOGY"] = {  -- updated: 2026/04/02
        ["Overall BiS"] = {
            { itemID = 249283, source = "Belo'ren" },  -- Weapon: Belo'melorn, the Shattered Talon
            { itemID = 249276, source = "Vorasius" },  -- Off-Hand: Grimoire of the Eternal Light
            { itemID = 250042, source = "Tier Set" },  -- Head: Abyssal Immolator's Smoldering Flames
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 251085, source = "Windrunner Spire" },  -- Shoulders: Mantle of Dark Devotion
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250045, source = "Tier Set" },  -- Chest: Abyssal Immolator's Dreadrobe
            { itemID = 239648, source = "Crafted" },  -- Wrist: Martyr's Bindings
            { itemID = 250043, source = "Tier Set" },  -- Gloves: Abyssal Immolator's Grasps
            { itemID = 249376, source = "Belo'ren" },  -- Belt: Whisper-Inscribed Sash
            { itemID = 250041, source = "Tier Set" },  -- Legs: Abyssal Immolator's Pillars
            { itemID = 249305, source = "Vaelgor" },  -- Boots: Slippers of the Midnight Flame
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 251217, source = "Nexus Point Xenas" },  -- Ring: Occlusion of Void
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket: Emberwing Feather
            { itemID = 249809, source = "Crown of the Cosmos" },  -- Trinket: Locus-Walker's Ribbon
            { itemID = 249346, source = "Vaelgor" },  -- Alt Trinket: Vaelgor's Final Stare
        },
        ["M+ BiS"] = {
            { itemID = 250042, source = "Matrix Catalyst" },  -- Head: Abyssal Immolator's Smoldering Flames
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 251085, source = "Windrunner Spire" },  -- Shoulder: Mantle of Dark Devotion
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250045, source = "Matrix Catalyst" },  -- Chest: Abyssal Immolator's Dreadrobe
            { itemID = 239648, source = "Crafted by Tailoring" },  -- Wrists: Martyr's Bindings
            { itemID = 250043, source = "Matrix Catalyst" },  -- Hands: Abyssal Immolator's Grasps
            { itemID = 151302, source = "Seat of the Triumvirate" },  -- Belt: Cord of Unraveling Reality
            { itemID = 250041, source = "Matrix Catalyst" },  -- Legs: Abyssal Immolator's Pillars
            { itemID = 251167, source = "Maisara Caverns" },  -- Feet: Nightprey Stalkers
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 250144, source = "Windrunner Spire" },  -- Trinket #1: Emberwing Feather
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #2: Heart of Wind
            { itemID = 258047, source = "Skyreach" },  -- Weapon: Spire of the Furious Construct
        },
    },
    ["WARLOCK_DESTRUCTION"] = {  -- updated: 2026/04/05
        ["Overall BiS"] = {
            { itemID = 249283, source = "Belo'ren" },  -- Weapon: Belo'melorn, the Shattered Talon
            { itemID = 249276, source = "Vorasius" },  -- Off-Hand: Grimoire of the Eternal Light
            { itemID = 250042, source = "Tier Set" },  -- Head: Abyssal Immolator's Smoldering Flames
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 251085, source = "Windrunner Spire" },  -- Shoulders: Mantle of Dark Devotion
            { itemID = 239656, source = "Crafting" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250045, source = "Tier Set" },  -- Chest: Abyssal Immolator's Dreadrobe
            { itemID = 239648, source = "Crafted" },  -- Wrist: Martyr's Bindings
            { itemID = 250043, source = "Tier Set" },  -- Gloves: Abyssal Immolator's Grasps
            { itemID = 249376, source = "Belo'ren" },  -- Belt: Whisper-Inscribed Sash
            { itemID = 250041, source = "Tier Set" },  -- Legs: Abyssal Immolator's Pillars
            { itemID = 249305, source = "Vaelgor" },  -- Boots: Slippers of the Midnight Flame
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 251217, source = "Nexus Point Xenas" },  -- Ring: Occlusion of Void
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249346, source = "Vaelgor" },  -- Trinket: Vaelgor's Final Stare
        },
        ["M+ BiS"] = {
            { itemID = 250042, source = "Matrix Catalyst" },  -- Head: Abyssal Immolator's Smoldering Flames
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 251085, source = "Windrunner Spire" },  -- Shoulder: Mantle of Dark Devotion
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 250045, source = "Matrix Catalyst" },  -- Chest: Abyssal Immolator's Dreadrobe
            { itemID = 239648, source = "Crafted by Tailoring" },  -- Wrists: Martyr's Bindings
            { itemID = 250043, source = "Matrix Catalyst" },  -- Hands: Abyssal Immolator's Grasps
            { itemID = 151302, source = "Seat of the Triumvirate" },  -- Belt: Cord of Unraveling Reality
            { itemID = 250041, source = "Matrix Catalyst" },  -- Legs: Abyssal Immolator's Pillars
            { itemID = 251167, source = "Maisara Caverns" },  -- Feet: Nightprey Stalkers
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #1: Heart of Wind
            { itemID = 250258, source = "Maisara Caverns" },  -- Trinket #2: Vessel of Tortured Souls
            { itemID = 258047, source = "Skyreach" },  -- Weapon: Spire of the Furious Construct
        },
    },
    ["WARRIOR_ARMS"] = {  -- updated: 2026/03/05
        ["Overall BiS"] = {
            { itemID = 249952, source = "Tier Set" },  -- Helm: Night Ender's Tusks
            { itemID = 249337, source = "Fallen-King Salhadaar" },  -- Neck: Ribbon of Coiled Malice
            { itemID = 249950, source = "Tier Set" },  -- Shoulders: Night Ender's Pauldrons
            { itemID = 239656, source = "Crafted" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249955, source = "Chimaerus" },  -- Chest: Night Ender's Breastplate
            { itemID = 237834, source = "Crafted" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 251081, source = "Windrunner Spire" },  -- Gloves: Embergrove Grasps
            { itemID = 249949, source = "Catalyst" },  -- Belt: Night Ender's Girdle
            { itemID = 249951, source = "Tier Set" },  -- Legs: Night Ender's Chausses
            { itemID = 249381, source = "Chimaerus" },  -- Boots: Greaves of the Unformed
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 251217, source = "Nexus Point Xenas" },  -- Ring: Occlusion of Void
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249342, source = "Vorasius" },  -- Trinket: Heart of Ancient Hunger
            { itemID = 249296, source = "Midnight Falls" },  -- Mainhand: Alah'endal, the Dawnsong
        },
        ["M+ BiS"] = {
            { itemID = 49802, source = "Pit of Saron" },  -- Mainhand Weapon: Garfrost's Two-Ton Hammer
            { itemID = 249952, source = "Matrix Catalyst" },  -- Helm: Night Ender's Tusks
            { itemID = 50228, source = "Pit of Saron" },  -- Neck: Barbed Ymirheim Choker
            { itemID = 249950, source = "Matrix Catalyst" },  -- Shoulder: Night Ender's Pauldrons
            { itemID = 239656, source = "Crafted by Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249955, source = "Matrix Catalyst" },  -- Chest: Night Ender's Breastplate
            { itemID = 237834, source = "Crafted by Blacksmithing" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 49808, source = "Pit of Saron" },  -- Belt: Bent Gold Belt
            { itemID = 249951, source = "Matrix Catalyst" },  -- Legs: Night Ender's Chausses
            { itemID = 251107, source = "Magister's Terrace" },  -- Boots: Oathsworn Stompers
            { itemID = 49812, source = "Pit of Saron" },  -- Ring #1: Purloined Wedding Ring
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["WARRIOR_FURY"] = {  -- updated: 2026/03/16
        ["Overall BiS"] = {
            { itemID = 249952, source = "Tier Set" },  -- Helm: Night Ender's Tusks
            { itemID = 250247, source = "Midnight Falls" },  -- Neck: Amulet of the Abyssal Hymn
            { itemID = 249950, source = "Tier Set" },  -- Shoulders: Night Ender's Pauldrons
            { itemID = 258575, source = "Skyreach" },  -- Cloak: Rigid Scale Greatcloak
            { itemID = 249955, source = "Chimaerus" },  -- Chest: Night Ender's Breastplate
            { itemID = 237834, source = "Crafted" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 249949, source = "Catalyst" },  -- Belt: Night Ender's Girdle
            { itemID = 249951, source = "Tier Set" },  -- Legs: Night Ender's Chausses
            { itemID = 249954, source = "Catalyst" },  -- Boots: Night Ender's Greatboots
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 193708, source = "Algeth'ar Academy" },  -- Ring: Platinum Star Band
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249342, source = "Vorasius" },  -- Trinket: Heart of Ancient Hunger
            { itemID = 249277, source = "Lightblinded Vanguard" },  -- Mainhand: Bellamy's Final Judgement
            { itemID = 237846, source = "Crafted" },  -- Offhand: Blood Knight's Warblade
        },
        ["M+ BiS"] = {
            { itemID = 251117, source = "Magister's Terrace" },  -- Mainhand Weapon: Whirling Voidcleaver
            { itemID = 237847, source = "Crafted by Blacksmithing" },  -- Offhand Weapon: Blood Knight's Impetus
            { itemID = 251098, source = "Windrunner Spire" },  -- Helm: Fletcher's Faded Faceplate
            { itemID = 151309, source = "Seat of the Triumvirate" },  -- Neck: Necklace of the Twisting Void
            { itemID = 251164, source = "Maisara Caverns" },  -- Shoulder: Amalgamation's Harness
            { itemID = 260312, source = "Magister's Terrace" },  -- Cloak: Defiant Defender's Drape
            { itemID = 151329, source = "Seat of the Triumvirate" },  -- Chest: Breastplate of the Dark Touch
            { itemID = 237834, source = "Crafted by Blacksmithing" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 151327, source = "Seat of the Triumvirate" },  -- Belt: Girdle of the Shadowguard
            { itemID = 251118, source = "Magister's Terrace" },  -- Legs: Legplates of Lingering Dusk
            { itemID = 251107, source = "Magister's Terrace" },  -- Boots: Oathsworn Stompers
            { itemID = 251115, source = "Magister's Terrace" },  -- Ring #1: Bifurcation Band
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #2: Omission of Light
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 252420, source = "Skyreach" },  -- Trinket #2: Solarflare Prism
        },
    },
    ["WARRIOR_PROTECTION"] = {  -- updated: 2026/03/19
        ["Overall BiS"] = {
            { itemID = 249295, source = "Crown of the Cosmos" },  -- Weapon: Turalyon's False Echo
            { itemID = 249921, source = "Belo'ren" },  -- Offhand: Thalassian Dawnguard
            { itemID = 249952, source = "Tier Set" },  -- Head: Night Ender's Tusks
            { itemID = 249368, source = "Crown of the Cosmos" },  -- Neck: Eternal Voidsong Chain
            { itemID = 249950, source = "Tier Set" },  -- Shoulders: Night Ender's Pauldrons
            { itemID = 249370, source = "Vaelgor & Ezzorak" },  -- Cloak: Draconic Nullcape
            { itemID = 249955, source = "Tier Set" },  -- Chest: Night Ender's Breastplate
            { itemID = 249326, source = "Imperator Averzian" },  -- Wrist: Light's March Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 249331, source = "Vaelgor & Ezzorak" },  -- Belt: Ezzorak's Gloombind
            { itemID = 249951, source = "Tier Set" },  -- Legs: Night Ender's Chausses
            { itemID = 249381, source = "Chimaerus" },  -- Boots: Greaves of the Unformed
            { itemID = 249920, source = "Midnight Falls" },  -- Ring: Eye of Midnight
            { itemID = 151311, source = "Seat of the Triumvirate" },  -- Ring: Band of the Triumvirate
            { itemID = 249343, source = "Chimaerus" },  -- Trinket: Gaze of the Alnseer
            { itemID = 249342, source = "Vorasius" },  -- Trinket: Heart of Ancient Hunger
        },
        ["M+ BiS"] = {
            { itemID = 249952, source = "Matrix Catalyst" },  -- Helm: Night Ender's Tusks
            { itemID = 151309, source = "Seat of the Triumvirate" },  -- Neck: Necklace of the Twisting Void
            { itemID = 249950, source = "Matrix Catalyst" },  -- Shoulder: Night Ender's Pauldrons
            { itemID = 239656, source = "Crafted — Tailoring" },  -- Cloak: Adherent's Silken Shroud
            { itemID = 249955, source = "Matrix Catalyst" },  -- Chest: Night Ender's Breastplate
            { itemID = 237834, source = "Crafted — Blacksmithing" },  -- Bracers: Spellbreaker's Bracers
            { itemID = 151332, source = "Seat of the Triumvirate" },  -- Gloves: Voidclaw Gauntlets
            { itemID = 251086, source = "Windrunner Spire" },  -- Belt: Riphook Defender
            { itemID = 249951, source = "Matrix Catalyst" },  -- Legs: Night Ender's Chausses
            { itemID = 249954, source = "Matrix Catalyst" },  -- Boots: Night Ender's Greatboots
            { itemID = 251093, source = "Nexus-Point Xenas" },  -- Ring #1: Omission of Light
            { itemID = 251217, source = "Nexus-Point Xenas" },  -- Ring #2: Occlusion of Void
            { itemID = 193701, source = "Algeth'ar Academy" },  -- Trinket #1: Algeth'ar Puzzle Box
            { itemID = 250256, source = "Windrunner Spire" },  -- Trinket #2: Heart of Wind
            { itemID = 258525, source = "Seat of the Triumvirate" },  -- Weapon: Scepter of the Endless Night
            { itemID = 251105, source = "Magister's Terrace" },  -- Shield: Ward of the Spellbreaker
        },
    },
}
