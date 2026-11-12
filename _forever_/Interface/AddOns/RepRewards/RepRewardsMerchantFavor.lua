-------------------------------------------------------------------------
-- RepRewardsMerchantFavor.lua
-- Shared ACA / DSL Merchant's Favor vendor recipes (Neutral standing)
-- Item IDs from Wowhead Forever Horde profession vendors:
--   Gor'mak (248197), Pawani (248201), Jim'bek (248202),
--   Beneris (248199), Apothecary Durelle (248196),
--   Fizzlefuse (248200), Aza'bek (248198)
-------------------------------------------------------------------------

local S = RepRewards_Data.STANDING

-- MF(itemID, cost, opts) - name/icon/stats resolve from the client.
-- opts: skill, profession, type, note
local function MF(itemID, cost, opts)
	opts = opts or {}
	local note = cost and (tostring(cost) .. " Merchant's Favor") or nil
	if opts.skill then
		note = (note and (note .. "; skill " .. opts.skill) or ("skill " .. opts.skill))
	end
	if opts.note then
		note = opts.note
	end
	return RepRewards_Data.NormalizeReward({
		itemID = itemID,
		standing = S.NEUTRAL,
		type = opts.type or "Recipe",
		note = note,
		skill = opts.skill,
		profession = opts.profession,
		professionLocked = opts.profession ~= nil,
	})
end

local shared = {}
local function add(r) shared[#shared + 1] = r end

-- Blacksmithing (62) - Wowhead Forever vendor sells
local P = "Blacksmithing"
add(MF(271622, 1000, { skill = 300, type = "Misc", profession = P }))  -- Blacksmithing Certification
add(MF(251365, 30, { skill = 45, profession = P }))  -- Plans: Veteran's Chain Belt
add(MF(251366, 30, { skill = 45, profession = P }))  -- Plans: Guard's Chain Belt
add(MF(251367, 30, { skill = 45, profession = P }))  -- Plans: Protector's Chain Belt
add(MF(251368, 30, { skill = 45, profession = P }))  -- Plans: Acolyte's Chain Belt
add(MF(251369, 30, { skill = 45, profession = P }))  -- Plans: Crusader's Chain Belt
add(MF(251360, 30, { skill = 80, profession = P }))  -- Plans: Veteran's Gloves
add(MF(251361, 30, { skill = 80, profession = P }))  -- Plans: Guard's Gloves
add(MF(251362, 30, { skill = 80, profession = P }))  -- Plans: Protector's Gloves
add(MF(251363, 30, { skill = 80, profession = P }))  -- Plans: Acolyte's Gloves
add(MF(251364, 30, { skill = 80, profession = P }))  -- Plans: Crusader's Gloves
add(MF(251355, 30, { skill = 85, profession = P }))  -- Plans: Veteran's Boots
add(MF(251356, 30, { skill = 85, profession = P }))  -- Plans: Guard's Boots
add(MF(251357, 30, { skill = 85, profession = P }))  -- Plans: Protector's Boots
add(MF(251358, 30, { skill = 85, profession = P }))  -- Plans: Acolyte's Boots
add(MF(251359, 30, { skill = 85, profession = P }))  -- Plans: Crusader's Boots
add(MF(251380, 30, { skill = 95, profession = P }))  -- Plans: Veteran's Silvered Chain Helm
add(MF(251381, 30, { skill = 95, profession = P }))  -- Plans: Guard's Silvered Chain Helm
add(MF(251382, 30, { skill = 95, profession = P }))  -- Plans: Protector's Silvered Chain Helm
add(MF(251383, 30, { skill = 95, profession = P }))  -- Plans: Acolyte's Silvered Chain Helm
add(MF(251384, 30, { skill = 95, profession = P }))  -- Plans: Crusader's Silvered Chain Helm
add(MF(251370, 30, { skill = 110, profession = P }))  -- Plans: Veteran's Silvered Chain Shirt
add(MF(251371, 30, { skill = 110, profession = P }))  -- Plans: Guard's Silvered Chain Shirt
add(MF(251372, 30, { skill = 110, profession = P }))  -- Plans: Protector's Silvered Chain Shirt
add(MF(251373, 30, { skill = 110, profession = P }))  -- Plans: Acolyte's Silvered Chain Shirt
add(MF(251374, 30, { skill = 110, profession = P }))  -- Plans: Crusader's Silvered Chain Shirt
add(MF(251375, 30, { skill = 125, profession = P }))  -- Plans: Veteran's Silvered Chain Leggings
add(MF(251376, 30, { skill = 125, profession = P }))  -- Plans: Guard's Silvered Chain Leggings
add(MF(251377, 30, { skill = 125, profession = P }))  -- Plans: Protector's Silvered Chain Leggings
add(MF(251378, 30, { skill = 125, profession = P }))  -- Plans: Acolyte's Silvered Chain Leggings
add(MF(251379, 30, { skill = 125, profession = P }))  -- Plans: Crusader's Silvered Chain Leggings
add(MF(251418, 60, { skill = 175, profession = P }))  -- Plans: Officer's Gauntlet
add(MF(251419, 60, { skill = 175, profession = P }))  -- Plans: Sentinel's Gauntlet
add(MF(251420, 60, { skill = 175, profession = P }))  -- Plans: Warder's Gauntlet
add(MF(251421, 60, { skill = 175, profession = P }))  -- Plans: Prefect's Gauntlet
add(MF(251422, 60, { skill = 175, profession = P }))  -- Plans: Justicar's Gauntlet
add(MF(251428, 60, { skill = 210, profession = P }))  -- Plans: Officer's Pauldrons
add(MF(251429, 60, { skill = 210, profession = P }))  -- Plans: Sentinel's Pauldrons
add(MF(251430, 60, { skill = 210, profession = P }))  -- Plans: Warder's Pauldrons
add(MF(251431, 60, { skill = 210, profession = P }))  -- Plans: Prefect's Pauldrons
add(MF(251432, 60, { skill = 210, profession = P }))  -- Plans: Justicar's Pauldrons
add(MF(251433, 90, { skill = 225, profession = P }))  -- Plans: Officer's Wristguard
add(MF(251434, 90, { skill = 225, profession = P }))  -- Plans: Sentinel's Wristguard
add(MF(251435, 90, { skill = 225, profession = P }))  -- Plans: Warder's Wristguard
add(MF(251436, 90, { skill = 225, profession = P }))  -- Plans: Prefect's Wristguard
add(MF(251437, 90, { skill = 225, profession = P }))  -- Plans: Justicar's Wristguards
add(MF(251413, 90, { skill = 240, profession = P }))  -- Plans: Officer's Sabatons
add(MF(251414, 90, { skill = 240, profession = P }))  -- Plans: Sentinel's Sabatons
add(MF(251415, 90, { skill = 240, profession = P }))  -- Plans: Warder's Sabatons
add(MF(251416, 90, { skill = 240, profession = P }))  -- Plans: Prefect's Sabatons
add(MF(251417, 90, { skill = 240, profession = P }))  -- Plans: Justicar's Sabatons
add(MF(251423, 90, { skill = 250, profession = P }))  -- Plans: Officer's Waistguard
add(MF(251424, 90, { skill = 250, profession = P }))  -- Plans: Sentinel's Waistguard
add(MF(251425, 90, { skill = 250, profession = P }))  -- Plans: Warder's Waistguard
add(MF(251426, 90, { skill = 250, profession = P }))  -- Plans: Prefect's Waistguard
add(MF(251427, 90, { skill = 250, profession = P }))  -- Plans: Justicar's Waistguard
add(MF(251465, 90, { skill = 250, profession = P }))  -- Plans: Thorium Greatmace
add(MF(251466, 90, { skill = 250, profession = P }))  -- Plans: Thorium Cestus
add(MF(251447, 120, { skill = 300, profession = P }))  -- Plans: Enriched Thorium Breastplate
add(MF(251448, 120, { skill = 300, profession = P }))  -- Plans: Enriched Thorium Leggings
add(MF(251449, 120, { skill = 300, profession = P }))  -- Plans: Enriched Thorium Helm
add(MF(251471, 120, { skill = 300, profession = P }))  -- Plans: Legionite Glaive

-- Leatherworking (82) - Wowhead Forever vendor sells
local P = "Leatherworking"
add(MF(271626, 1000, { skill = 300, type = "Misc", profession = P }))  -- Leatherworking Certification
add(MF(252765, 30, { skill = 60, profession = P }))  -- Pattern: Brawler's Leather Belt
add(MF(252766, 30, { skill = 60, profession = P }))  -- Pattern: Trapper's Leather Belt
add(MF(252767, 30, { skill = 60, profession = P }))  -- Pattern: Defender's Leather Belt
add(MF(252768, 30, { skill = 60, profession = P }))  -- Pattern: Totemic Leather Belt
add(MF(252769, 30, { skill = 60, profession = P }))  -- Pattern: Stormrider's Leather Belt
add(MF(252770, 30, { skill = 60, profession = P }))  -- Pattern: Wisdom's Leather Belt
add(MF(252777, 30, { skill = 75, profession = P }))  -- Pattern: Brawler's Leather Gloves
add(MF(252778, 30, { skill = 75, profession = P }))  -- Pattern: Trapper's Leather Gloves
add(MF(252779, 30, { skill = 75, profession = P }))  -- Pattern: Defender's Leather Gloves
add(MF(252780, 30, { skill = 75, profession = P }))  -- Pattern: Totemic Leather Gloves
add(MF(252781, 30, { skill = 75, profession = P }))  -- Pattern: Stormrider's Leather Gloves
add(MF(252782, 30, { skill = 75, profession = P }))  -- Pattern: Wisdom's Leather Gloves
add(MF(252786, 30, { skill = 85, profession = P }))  -- Pattern: Brawler's Leather Boots
add(MF(252787, 30, { skill = 85, profession = P }))  -- Pattern: Trapper's Leather Boots
add(MF(252788, 30, { skill = 85, profession = P }))  -- Pattern: Defender's Leather Boots
add(MF(252789, 30, { skill = 85, profession = P }))  -- Pattern: Totemic Leather Boots
add(MF(252790, 30, { skill = 85, profession = P }))  -- Pattern: Stormrider's Leather Boots
add(MF(252791, 30, { skill = 85, profession = P }))  -- Pattern: Wisdom's Leather Boots
add(MF(252798, 30, { skill = 100, profession = P }))  -- Pattern: Brawler's Leather Hood
add(MF(252799, 30, { skill = 100, profession = P }))  -- Pattern: Trapper's Leather Hood
add(MF(252800, 30, { skill = 100, profession = P }))  -- Pattern: Defender's Leather Hood
add(MF(252801, 30, { skill = 100, profession = P }))  -- Pattern: Totemic Leather Hood
add(MF(252802, 30, { skill = 100, profession = P }))  -- Pattern: Stormrider's Leather Hood
add(MF(252803, 30, { skill = 100, profession = P }))  -- Pattern: Wisdom's Leather Hood
add(MF(252805, 30, { skill = 110, profession = P }))  -- Pattern: Brawler's Leather Tunic
add(MF(252806, 30, { skill = 110, profession = P }))  -- Pattern: Trapper's Leather Tunic
add(MF(252807, 30, { skill = 110, profession = P }))  -- Pattern: Defender's Leather Tunic
add(MF(252808, 30, { skill = 110, profession = P }))  -- Pattern: Totemic Leather Tunic
add(MF(252809, 30, { skill = 110, profession = P }))  -- Pattern: Stormrider's Leather Tunic
add(MF(252810, 30, { skill = 110, profession = P }))  -- Pattern: Wisdom's Leather Tunic
add(MF(252820, 30, { skill = 125, profession = P }))  -- Pattern: Brawler's Leather Legguards
add(MF(252821, 30, { skill = 125, profession = P }))  -- Pattern: Trapper's Leather Legguards
add(MF(252822, 30, { skill = 125, profession = P }))  -- Pattern: Defender's Leather Kilt
add(MF(252823, 30, { skill = 125, profession = P }))  -- Pattern: Totemic Leather Leggings
add(MF(252824, 30, { skill = 125, profession = P }))  -- Pattern: Stormrider's Leather Kilt
add(MF(252825, 30, { skill = 125, profession = P }))  -- Pattern: Wisdom's Leather Leggings
add(MF(252836, 60, { skill = 175, profession = P }))  -- Pattern: Prowler's Leather Gloves
add(MF(252837, 60, { skill = 175, profession = P }))  -- Pattern: Skulker's Leather Gloves
add(MF(252838, 60, { skill = 175, profession = P }))  -- Pattern: Stalker's Leather Gloves
add(MF(252839, 60, { skill = 175, profession = P }))  -- Pattern: Warden's Leather Gloves
add(MF(252840, 60, { skill = 175, profession = P }))  -- Pattern: Skirmisher's Leather Gloves
add(MF(252841, 60, { skill = 175, profession = P }))  -- Pattern: Skycaller's Leather Gloves
add(MF(252842, 60, { skill = 175, profession = P }))  -- Pattern: Mender's Leather Gloves
add(MF(252834, 60, { skill = 185, profession = P }))  -- Pattern: Forceful Thick Armor Kit
add(MF(252848, 60, { skill = 210, profession = P }))  -- Pattern: Prowler's Leather Shoulder
add(MF(252849, 60, { skill = 210, profession = P }))  -- Pattern: Skulker's Leather Shoulder
add(MF(252850, 60, { skill = 210, profession = P }))  -- Pattern: Warden's Leather Shoulder
add(MF(252851, 60, { skill = 210, profession = P }))  -- Pattern: Skycaller's Leather Shoulder
add(MF(252852, 60, { skill = 210, profession = P }))  -- Pattern: Mender's Leather Shoulder
add(MF(252900, 60, { skill = 210, profession = P }))  -- Pattern: Stalker's Mail Shoulder
add(MF(252901, 60, { skill = 210, profession = P }))  -- Pattern: Skycaller's Mail Shoulder
add(MF(252902, 60, { skill = 210, profession = P }))  -- Pattern: Skirmisher's Mail Shoulder
add(MF(252903, 60, { skill = 210, profession = P }))  -- Pattern: Mender's Mail Shoulder
add(MF(252853, 90, { skill = 225, profession = P }))  -- Pattern: Prowler's Leather Bracers
add(MF(252854, 90, { skill = 225, profession = P }))  -- Pattern: Skulker's Leather Bracers
add(MF(252855, 90, { skill = 225, profession = P }))  -- Pattern: Warden's Leather Bracers
add(MF(252856, 90, { skill = 225, profession = P }))  -- Pattern: Skycaller's Leather Bracers
add(MF(252857, 90, { skill = 225, profession = P }))  -- Pattern: Mender's Leather Bracers
add(MF(252904, 90, { skill = 225, profession = P }))  -- Pattern: Stalker's Mail Bracers
add(MF(252905, 90, { skill = 225, profession = P }))  -- Pattern: Skycaller's Mail Bracers
add(MF(252906, 90, { skill = 225, profession = P }))  -- Pattern: Skirmisher's Mail Bracers
add(MF(252907, 90, { skill = 225, profession = P }))  -- Pattern: Mender's Mail Bracers
add(MF(252860, 90, { skill = 235, profession = P }))  -- Pattern: Prowler's Leather Boots
add(MF(252861, 90, { skill = 235, profession = P }))  -- Pattern: Skulker's Leather Boots
add(MF(252862, 90, { skill = 235, profession = P }))  -- Pattern: Warden's Leather Boots
add(MF(252863, 90, { skill = 235, profession = P }))  -- Pattern: Skycaller's Leather Boots
add(MF(252864, 90, { skill = 235, profession = P }))  -- Pattern: Mender's Leather Boots
add(MF(252910, 90, { skill = 235, profession = P }))  -- Pattern: Stalker's Mail Sabatons
add(MF(252911, 90, { skill = 235, profession = P }))  -- Pattern: Skycaller's Mail Sabatons
add(MF(252912, 90, { skill = 235, profession = P }))  -- Pattern: Skirmisher's Mail Sabatons
add(MF(252913, 90, { skill = 235, profession = P }))  -- Pattern: Mender's Mail Sabatons
add(MF(252941, 90, { skill = 235, profession = P }))  -- Pattern: Mystic Rugged Armor Kit
add(MF(252872, 90, { skill = 250, profession = P }))  -- Pattern: Prowler's Leather Waistguard
add(MF(252873, 90, { skill = 250, profession = P }))  -- Pattern: Skulker's Leather Waistguard
add(MF(252874, 90, { skill = 250, profession = P }))  -- Pattern: Warden's Leather Waistguard
add(MF(252875, 90, { skill = 250, profession = P }))  -- Pattern: Skycaller's Leather Waistguard
add(MF(252876, 90, { skill = 250, profession = P }))  -- Pattern: Mender's Leather Waistguard
add(MF(252922, 90, { skill = 250, profession = P }))  -- Pattern: Stalker's Mail Belt
add(MF(252923, 90, { skill = 250, profession = P }))  -- Pattern: Skycaller's Mail Belt
add(MF(252924, 90, { skill = 250, profession = P }))  -- Pattern: Skirmisher's Mail Belt
add(MF(252925, 90, { skill = 250, profession = P }))  -- Pattern: Mender's Mail Belt

-- Tailoring (68) - Wowhead Forever vendor sells
local P = "Tailoring"
add(MF(271627, 1000, { skill = 300, type = "Misc", profession = P }))  -- Tailoring Certification
add(MF(253890, 30, { skill = 60, profession = P }))  -- Pattern: Pristine Boots
add(MF(253892, 30, { skill = 60, profession = P }))  -- Pattern: Silky Boots
add(MF(253894, 30, { skill = 60, profession = P }))  -- Pattern: Flame Boots
add(MF(253896, 30, { skill = 60, profession = P }))  -- Pattern: Shadow Boots
add(MF(253898, 30, { skill = 60, profession = P }))  -- Pattern: Pearly Boots
add(MF(253900, 30, { skill = 60, profession = P }))  -- Pattern: Shining Boots
add(MF(253914, 30, { skill = 75, profession = P }))  -- Pattern: Pristine Gloves
add(MF(253916, 30, { skill = 75, profession = P }))  -- Pattern: Silky Gloves
add(MF(253918, 30, { skill = 75, profession = P }))  -- Pattern: Flame Gloves
add(MF(253920, 30, { skill = 75, profession = P }))  -- Pattern: Shadow Gloves
add(MF(253922, 30, { skill = 75, profession = P }))  -- Pattern: Pearly Gloves
add(MF(253924, 30, { skill = 75, profession = P }))  -- Pattern: Shining Gloves
add(MF(253926, 30, { skill = 85, profession = P }))  -- Pattern: Pristine Sash
add(MF(253928, 30, { skill = 85, profession = P }))  -- Pattern: Silky Sash
add(MF(253930, 30, { skill = 85, profession = P }))  -- Pattern: Flame Sash
add(MF(253932, 30, { skill = 85, profession = P }))  -- Pattern: Shadow Sash
add(MF(253934, 30, { skill = 85, profession = P }))  -- Pattern: Pearly Sash
add(MF(253936, 30, { skill = 85, profession = P }))  -- Pattern: Shining Sash
add(MF(253950, 30, { skill = 100, profession = P }))  -- Pattern: Pristine Circlet
add(MF(253952, 30, { skill = 100, profession = P }))  -- Pattern: Silky Circlet
add(MF(253954, 30, { skill = 100, profession = P }))  -- Pattern: Flame Circlet
add(MF(253956, 30, { skill = 100, profession = P }))  -- Pattern: Shadow Circlet
add(MF(253958, 30, { skill = 100, profession = P }))  -- Pattern: Pearly Circlet
add(MF(253960, 30, { skill = 100, profession = P }))  -- Pattern: Shining Circlet
add(MF(253962, 30, { skill = 110, profession = P }))  -- Pattern: Pristine Gown
add(MF(253964, 30, { skill = 110, profession = P }))  -- Pattern: Silky Gown
add(MF(253966, 30, { skill = 110, profession = P }))  -- Pattern: Flame Gown
add(MF(253968, 30, { skill = 110, profession = P }))  -- Pattern: Shadow Gown
add(MF(253970, 30, { skill = 110, profession = P }))  -- Pattern: Pearly Gown
add(MF(253972, 30, { skill = 110, profession = P }))  -- Pattern: Shining Gown
add(MF(253988, 30, { skill = 125, profession = P }))  -- Pattern: Pristine Leggings
add(MF(253990, 30, { skill = 125, profession = P }))  -- Pattern: Silky Leggings
add(MF(253992, 30, { skill = 125, profession = P }))  -- Pattern: Flame Leggings
add(MF(253994, 30, { skill = 125, profession = P }))  -- Pattern: Shadow Leggings
add(MF(253996, 30, { skill = 125, profession = P }))  -- Pattern: Pearly Leggings
add(MF(253998, 30, { skill = 125, profession = P }))  -- Pattern: Shining Leggings
add(MF(254024, 60, { skill = 165, profession = P }))  -- Pattern: Frothing Handwraps
add(MF(254026, 60, { skill = 165, profession = P }))  -- Pattern: Fiery Handwraps
add(MF(254028, 60, { skill = 165, profession = P }))  -- Pattern: Black Handwraps
add(MF(254030, 60, { skill = 165, profession = P }))  -- Pattern: Golden Handwraps
add(MF(254032, 60, { skill = 165, profession = P }))  -- Pattern: Radiant Handwraps
add(MF(254036, 60, { skill = 190, profession = P }))  -- Pattern: Mageweave Reagent Bag
add(MF(254050, 60, { skill = 195, profession = P }))  -- Pattern: Nethergeld Shoulders
add(MF(254052, 60, { skill = 195, profession = P }))  -- Pattern: Netherfroth Shoulders
add(MF(254054, 60, { skill = 195, profession = P }))  -- Pattern: Netherflame Shoulders
add(MF(254056, 60, { skill = 195, profession = P }))  -- Pattern: Netherpearl Shoulders
add(MF(254058, 60, { skill = 195, profession = P }))  -- Pattern: Nethershine Shoulders
add(MF(254060, 60, { skill = 195, profession = P }))  -- Pattern: Netherlight Shoulders
add(MF(254062, 60, { skill = 205, profession = P }))  -- Pattern: Nethergeld Cuffs
add(MF(254064, 60, { skill = 205, profession = P }))  -- Pattern: Netherfroth Cuffs
add(MF(254066, 60, { skill = 205, profession = P }))  -- Pattern: Netherflame Cuffs
add(MF(254068, 60, { skill = 205, profession = P }))  -- Pattern: Netherpearl Cuffs
add(MF(254070, 60, { skill = 205, profession = P }))  -- Pattern: Nethershine Cuffs
add(MF(254072, 60, { skill = 205, profession = P }))  -- Pattern: Netherlight Cuffs
add(MF(254080, 60, { skill = 215, profession = P }))  -- Pattern: Runecloth Reagent Bag
add(MF(254082, 60, { skill = 215, profession = P }))  -- Pattern: Gilded Waistcord
add(MF(254084, 60, { skill = 215, profession = P }))  -- Pattern: Frothing Waistcord
add(MF(254086, 60, { skill = 215, profession = P }))  -- Pattern: Fiery Waistcord
add(MF(254088, 60, { skill = 215, profession = P }))  -- Pattern: Black Waistcord
add(MF(254090, 60, { skill = 215, profession = P }))  -- Pattern: Golden Waistcord
add(MF(254092, 60, { skill = 215, profession = P }))  -- Pattern: Radiant Waistcord
add(MF(254108, 90, { skill = 235, profession = P }))  -- Pattern: Gilded Sandals
add(MF(254110, 90, { skill = 235, profession = P }))  -- Pattern: Frothing Sandals
add(MF(254112, 90, { skill = 235, profession = P }))  -- Pattern: Fiery Sandals
add(MF(254114, 90, { skill = 235, profession = P }))  -- Pattern: Black Sandals
add(MF(254116, 90, { skill = 235, profession = P }))  -- Pattern: Golden Sandals
add(MF(254118, 90, { skill = 235, profession = P }))  -- Pattern: Radiant Sandals

-- Enchanting (40) - Wowhead Forever vendor sells
local P = "Enchanting"
add(MF(271624, 1000, { skill = 300, type = "Misc", profession = P }))  -- Enchanting Certification
add(MF(249476, 45, { skill = 130, profession = P }))  -- Formula: Mystic Mushroom
add(MF(249477, 45, { skill = 130, profession = P }))  -- Formula: Tenets of the Silver Hand
add(MF(249478, 45, { skill = 130, profession = P }))  -- Formula: Polished Driftwood Icon
add(MF(249479, 45, { skill = 140, profession = P }))  -- Formula: Enchant Weapon - Insight
add(MF(249480, 45, { skill = 140, profession = P }))  -- Formula: Enchant Weapon - Recovery
add(MF(249481, 45, { skill = 140, profession = P }))  -- Formula: Enchant Weapon - Revelation
add(MF(249482, 45, { skill = 140, profession = P }))  -- Formula: Glimmering Staff
add(MF(249483, 45, { skill = 140, profession = P }))  -- Formula: Soulstaff
add(MF(249484, 45, { skill = 140, profession = P }))  -- Formula: Orb of Mystic Insight
add(MF(249485, 45, { skill = 140, profession = P }))  -- Formula: Orb of Souls
add(MF(249493, 120, { skill = 210, profession = P }))  -- Formula: Talons of Wrath
add(MF(249494, 120, { skill = 210, profession = P }))  -- Formula: Libram of Invocation
add(MF(249495, 120, { skill = 210, profession = P }))  -- Formula: Totem of Ancestral Protection
add(MF(249496, 120, { skill = 210, profession = P }))  -- Formula: Enchant Necklace - Strength
add(MF(249502, 120, { skill = 210, profession = P }))  -- Formula: Enchant Necklace - Spell Power
add(MF(249503, 120, { skill = 210, profession = P }))  -- Formula: Enchant Necklace - Healing Power
add(MF(249504, 120, { skill = 210, profession = P }))  -- Formula: Enchant Necklace - Agility
add(MF(249505, 120, { skill = 210, profession = P }))  -- Formula: Enchant Necklace - Deflection
add(MF(249506, 120, { skill = 220, profession = P }))  -- Formula: Radiant Staff
add(MF(249507, 120, { skill = 220, profession = P }))  -- Formula: Dreamstaff
add(MF(249508, 120, { skill = 220, profession = P }))  -- Formula: Truesilver Conduit
add(MF(249509, 120, { skill = 220, profession = P }))  -- Formula: Twisting Essence Jar
add(MF(249510, 120, { skill = 220, profession = P }))  -- Formula: Enchant Chest - Absorption
add(MF(249537, 180, { skill = 275, profession = P }))  -- Formula: Brilliant Wand
add(MF(249525, 240, { skill = 300, profession = P }))  -- Formula: Enchant 2H Weapon - Mighty Spell Power
add(MF(249526, 240, { skill = 300, profession = P }))  -- Formula: Enchant 2H Weapon - Mighty Healing Power
add(MF(249529, 240, { skill = 300, profession = P }))  -- Formula: Idol of the Dream
add(MF(249530, 240, { skill = 300, profession = P }))  -- Formula: Libram of Holy Alacrity
add(MF(249532, 240, { skill = 300, profession = P }))  -- Formula: Totem of Thunder
add(MF(249534, 240, { skill = 300, profession = P }))  -- Formula: Enchant Gloves - Arcane Power
add(MF(249535, 240, { skill = 300, profession = P }))  -- Formula: Enchant Gloves - Natural Power
add(MF(249536, 240, { skill = 300, profession = P }))  -- Formula: Enchant Gloves - Holy Power
add(MF(249538, 240, { skill = 300, profession = P }))  -- Formula: Enchant Bracer - Superior Intellect
add(MF(249539, 240, { skill = 300, profession = P }))  -- Formula: Enchant Bracer - Superior Deflection
add(MF(274393, 240, { skill = 300, profession = P }))  -- Formula: Enchant Off-Hand - Wisdom
add(MF(274394, 240, { skill = 300, profession = P }))  -- Formula: Enchant 2H Weapon - Spellblasting
add(MF(274398, 240, { skill = 300, profession = P }))  -- Formula: Enchant Gloves - Superior Strength
add(MF(274399, 240, { skill = 300, profession = P }))  -- Formula: Enchant Cloak - Agility
add(MF(274401, 240, { skill = 300, profession = P }))  -- Formula: Enchant Bracer - Greater Spellpower

-- Alchemy (30) - Wowhead Forever vendor sells
local P = "Alchemy"
add(MF(271621, 1000, { skill = 300, type = "Misc", profession = P }))  -- Alchemy Certification
add(MF(250381, 45, { skill = 65, profession = P }))  -- Recipe: Elixir of Lesser Spirit
add(MF(250376, 45, { skill = 75, profession = P }))  -- Recipe: Lesser Mageblood Elixir
add(MF(250367, 45, { skill = 95, profession = P }))  -- Recipe: Lesser Cleric's Elixir
add(MF(250388, 45, { skill = 95, profession = P }))  -- Recipe: Elixir of Lesser Intellect
add(MF(250378, 45, { skill = 120, profession = P }))  -- Recipe: Lesser Arcane Elixir
add(MF(250990, 45, { skill = 130, profession = P }))  -- Recipe: Mender's Potion
add(MF(250978, 45, { skill = 135, profession = P }))  -- Recipe: Spellblasting Potion
add(MF(250984, 45, { skill = 140, profession = P }))  -- Recipe: Frenzy Potion
add(MF(250383, 120, { skill = 165, profession = P }))  -- Recipe: Elixir of Greater Spirit
add(MF(250377, 120, { skill = 175, profession = P }))  -- Recipe: Greater Mageblood Elixir
add(MF(250996, 120, { skill = 180, profession = P }))  -- Recipe: Disorienting Smog Potion
add(MF(250369, 120, { skill = 195, profession = P }))  -- Recipe: Greater Cleric's Elixir
add(MF(250371, 120, { skill = 200, profession = P }))  -- Recipe: Elixir of Greater Fortitude
add(MF(250997, 120, { skill = 245, profession = P }))  -- Recipe: Dragonfire Potion
add(MF(250365, 180, { skill = 250, profession = P }))  -- Recipe: Elixir of the Phalanx
add(MF(250995, 180, { skill = 265, profession = P }))  -- Recipe: Caustic Smog Potion
add(MF(250364, 180, { skill = 275, profession = P }))  -- Recipe: Elixir of Cunning
add(MF(250374, 180, { skill = 275, profession = P }))  -- Recipe: Elixir of Sages
add(MF(250384, 180, { skill = 275, profession = P }))  -- Recipe: Elixir of the Whale
add(MF(250386, 180, { skill = 275, profession = P }))  -- Recipe: Elixir of Ferocity
add(MF(250994, 180, { skill = 275, profession = P }))  -- Recipe: Potion of Venomous Blood
add(MF(250373, 180, { skill = 280, profession = P }))  -- Recipe: Elixir of the Owl
add(MF(250993, 180, { skill = 280, profession = P }))  -- Recipe: Major Mender's Potion
add(MF(250998, 180, { skill = 280, profession = P }))  -- Recipe: Potion of Elemental Purging
add(MF(250372, 180, { skill = 285, profession = P }))  -- Recipe: Elixir of Wicked Regeneration
add(MF(250379, 180, { skill = 285, profession = P }))  -- Recipe: Elixir of Nature Power
add(MF(250981, 180, { skill = 285, profession = P }))  -- Recipe: Major Spellblasting Potion
add(MF(250987, 240, { skill = 290, profession = P }))  -- Recipe: Major Frenzy Potion
add(MF(250387, 240, { skill = 300, profession = P }))  -- Recipe: Elixir of the Grizzly

-- Engineering (29) - Wowhead Forever vendor sells
local P = "Engineering"
add(MF(271625, 1000, { skill = 300, type = "Misc", profession = P }))  -- Engineering Certification
add(MF(264201, 45, { skill = 25, profession = P }))  -- Schematic: SAF-T Tabs
add(MF(264202, 45, { skill = 25, profession = P }))  -- Schematic: SAF-T Dynamite
add(MF(264203, 45, { skill = 55, profession = P }))  -- Schematic: SAF-T Copper Bomb
add(MF(285285, 45, { skill = 85, profession = P }))  -- Schematic: Satchel of Copper Bombs
add(MF(264204, 45, { skill = 100, profession = P }))  -- Schematic: EZ-Thro Wrap
add(MF(264205, 45, { skill = 130, profession = P }))  -- Schematic: EZ-Thro Copper Bomb XL
add(MF(264206, 45, { skill = 145, profession = P }))  -- Schematic: No Slip SAF-T Padding
add(MF(285286, 180, { skill = 165, profession = P }))  -- Schematic: Satchel of Bronze Bombs
add(MF(264209, 180, { skill = 175, profession = P }))  -- Schematic: SAF-T Bell
add(MF(280321, 180, { skill = 175, profession = P }))  -- Schematic: Whimsical Waistwrap
add(MF(280322, 180, { skill = 175, profession = P }))  -- Schematic: Gizmo Girdle
add(MF(280323, 180, { skill = 175, profession = P }))  -- Schematic: Clanking Cord
add(MF(264211, 180, { skill = 190, profession = P }))  -- Schematic: EZ-Thro Fireproof Fuse
add(MF(280325, 180, { skill = 200, profession = P }))  -- Schematic: Floppy Goggles
add(MF(280326, 180, { skill = 200, profession = P }))  -- Schematic: Bent Goggles
add(MF(280327, 180, { skill = 200, profession = P }))  -- Schematic: Stuckbutton Goggles
add(MF(280328, 180, { skill = 200, profession = P }))  -- Schematic: Dented Goggles
add(MF(264216, 270, { skill = 225, profession = P }))  -- Schematic: Emergency Field Cloak
add(MF(264217, 270, { skill = 225, profession = P }))  -- Schematic: Compact Critter Carrier
add(MF(285287, 270, { skill = 230, profession = P }))  -- Schematic: Satchel of Iron Bombs
add(MF(264220, 270, { skill = 250, profession = P }))  -- Schematic: SAF-T Disposable Parachute
add(MF(264221, 270, { skill = 250, profession = P }))  -- Schematic: Gnomish Army Knife
add(MF(264222, 270, { skill = 275, profession = P }))  -- Schematic: Loot-A-Rang
add(MF(285288, 270, { skill = 285, profession = P }))  -- Schematic: Satchel of Dark Iron Bombs
add(MF(264232, 360, { skill = 300, profession = P }))  -- Schematic: Ultrasafe Rechargeable Battery
add(MF(264234, 360, { skill = 300, profession = P }))  -- Schematic: Gnomish Poultryizer
add(MF(264235, 360, { skill = 300, profession = P }))  -- Schematic: Ultralight Goblin Glider
add(MF(264237, 360, { skill = 300, profession = P }))  -- Schematic: Stealthman 52

-- Cooking (6) - Wowhead Forever vendor sells (Merchant's Favor only)
local P = "Cooking"
add(MF(249885, 30, { skill = 25, profession = P }))  -- Recipe: Venomous Smoothie
add(MF(249886, 30, { skill = 100, profession = P }))  -- Recipe: Slimy Smoothie
add(MF(249887, 30, { skill = 125, profession = P }))  -- Recipe: Mrrggl Smrrthle
add(MF(249888, 60, { skill = 180, profession = P }))  -- Recipe: Calcified Smoothie
add(MF(249889, 60, { skill = 200, profession = P }))  -- Recipe: Spicy Smoothie
add(MF(249890, 90, { skill = 250, profession = P }))  -- Recipe: Wicked Smoothie

function RepRewards_Data.GetMerchantFavorRecipes()
	return shared
end

function RepRewards_Data.BuildSupplyFactionRewards(factionSpecific)
	local list = {}
	for _, r in ipairs(factionSpecific or {}) do
		list[#list + 1] = RepRewards_Data.NormalizeReward(r)
	end
	for _, r in ipairs(shared) do
		list[#list + 1] = r
	end
	return list
end

-- Wire full reward lists onto ACA / DSL
do
	local function supplyReward(name, standing, opts)
		opts = opts or {}
		return RepRewards_Data.NormalizeReward({
			name = name,
			standing = standing,
			type = opts.type or "Misc",
			slot = opts.slot,
			note = opts.note,
			stats = opts.stats or {},
			itemID = opts.itemID,
		})
	end

	if RepRewards_Data.factions[2586] then
		RepRewards_Data.factions[2586].rewards = RepRewards_Data.BuildSupplyFactionRewards({
			supplyReward("Advertising License Application", S.HONORED, { type = "Toy", note = "1200 Merchant's Favor; starts Dwarven Tradeskill Sign quest" }),
			supplyReward("Azeroth Commerce Authority Tabard", S.EXALTED, { type = "Tabard", slot = "Tabard", note = "200 Merchant's Favor + 5g" }),
			supplyReward("Skyborne Tabard", S.EXALTED, { type = "Tabard", slot = "Tabard" }),
			supplyReward("Reins of the Pack Kodo", S.NEUTRAL, { type = "Mount", note = "6000 Merchant's Favor; level 60 + Journeyman Riding" }),
			supplyReward("Packmule Treat", S.NEUTRAL, { type = "Pet", note = "1500 Merchant's Favor; teaches Minimule" }),
		})
	end
	if RepRewards_Data.factions[2587] then
		RepRewards_Data.factions[2587].rewards = RepRewards_Data.BuildSupplyFactionRewards({
			supplyReward("Advertising License Application", S.HONORED, { type = "Toy", note = "1200 Merchant's Favor; starts Orcish Tradeskill Sign quest" }),
			supplyReward("Durotar Supply and Logistics Tabard", S.EXALTED, { type = "Tabard", slot = "Tabard", note = "200 Merchant's Favor + 5g" }),
			supplyReward("Reins of the Pack Kodo", S.NEUTRAL, { type = "Mount", note = "6000 Merchant's Favor; level 60 + Journeyman Riding" }),
			supplyReward("Packmule Treat", S.NEUTRAL, { type = "Pet", note = "1500 Merchant's Favor; teaches Minimule" }),
		})
	end
end
