local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local UnitLevel = UnitLevel
local UnitPowerMax = UnitPowerMax
local UnitRace = UnitRace
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local wipe = wipe
local tinsert = table.insert
local newItem = addon.functions.newItem

local _, race = UnitRace("player")
local isEarthen = (race == "EarthenDwarf")

addon.Drinks._wrapped = addon.Drinks._wrapped or {}
addon.Drinks._allowedCache = addon.Drinks._allowedCache or {}
addon.Drinks.filteredDrinks = addon.Drinks.filteredDrinks or {}
addon.Drinks.mageFood = addon.Drinks.mageFood or {}

local function wipeTable(tbl)
	if not tbl then return end
	if wipe then
		wipe(tbl)
	else
		for k in pairs(tbl) do
			tbl[k] = nil
		end
	end
end

local function wrapDrink(drink)
	if not drink or not drink.id then return nil end
	local key = (drink.isSpell and "s:" or "i:") .. tostring(drink.id)
	local obj = addon.Drinks._wrapped[key]
	if not obj then
		obj = newItem(drink.id, drink.desc, drink.isSpell)
		addon.Drinks._wrapped[key] = obj
	else
		obj.name = drink.desc
		obj.isSpell = drink.isSpell == true
	end
	return obj
end

local function ensureMageFoodMap()
	local drinks = addon.Drinks
	local mageFoodMap = drinks and drinks.mageFood
	if not drinks or not mageFoodMap then return end
	if drinks._mageFoodMapReady == true then return end

	wipeTable(mageFoodMap)
	local list = drinks.drinkList
	if not list then return end
	for i = 1, #list do
		local drink = list[i]
		if drink and drink.isMageFood and drink.id then mageFoodMap[drink.id] = true end
	end
	drinks._mageFoodMapReady = true
end

addon.Drinks.drinkList = { -- Special Food
	{ key = "ConjureRefreshment", id = 190336, requiredLevel = 5, mana = 0, isSpell = true }, -- set mana to zero, because we update it anyway
	{ key = "CandyBar", id = 20390, requiredLevel = 1, mana = 225000 }, -- We don't know the right amount on level 41 it's 18000
	{ key = "CandyCorn", id = 20389, requiredLevel = 1, mana = 225000 }, -- We don't know the right amount on level 41 it's 18000
	{ key = "ConjuredManaBun", id = 113509, requiredLevel = 40, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaFritter", id = 80618, requiredLevel = 35, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaPudding", id = 80610, requiredLevel = 35, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaCake", id = 65499, requiredLevel = 32, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaStrudel", id = 43523, requiredLevel = 30, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaPie", id = 43518, requiredLevel = 28, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaLollipop", id = 65517, requiredLevel = 26, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaCupcake", id = 65516, requiredLevel = 23, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaBrownie", id = 65515, requiredLevel = 19, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "ConjuredManaCookie", id = 65500, requiredLevel = 14, mana = 0, isMageFood = true, isEarthenFood = true }, -- set mana to zero, because we update it anyway
	{ key = "CrunchyRockCandy", id = 228494, requiredLevel = 1, mana = 3700000, isEarthenFood = true, earthenOnly = true }, -- Tooltip is wrong on this with "Buff Food"
	{ key = "ManagiRoll", id = 260255, requiredLevel = 80, mana = 0, isHealthOnly = true },
	{ key = "QuietContemplation", id = 461063, requiredLevel = 1, mana = 3700000, isEarthenFood = true, earthenOnly = true, isSpell = true },
	{ key = "Recuperate", id = 1231411, requiredLevel = 5, mana = 0, isSpell = true, isHealthOnly = true },

	{ key = "MarinatedMaggots", id = 226811, requiredLevel = 75, mana = 47724 },
	{ key = "GorlocFinSoup", id = 197847, requiredLevel = 10, mana = 53332 },
	{ key = "StrongSniffin'SoupforNiffen", id = 204790, requiredLevel = 65, mana = 53332 },
	{ key = "RefreshingSpringWater", id = 159, requiredLevel = 1, mana = 0, manaPercent = 1, manaDuration = 20 },
	{ key = "AzureLeywine", id = 194684, requiredLevel = 10, mana = 62500 },
	{ key = "BeetleJuice", id = 205794, requiredLevel = 65, mana = 62500 },
	{ key = "DeliciousDragonSpittle", id = 197771, requiredLevel = 65, mana = 71428 },
	{ key = "FreshlySqueezedMosswater", id = 204729, requiredLevel = 65, mana = 62500 },
	{ key = "EnchantedArgaliTenderloin", id = 197854, requiredLevel = 10, mana = 53332 },
	{ key = "ApexisAsiago", id = 201419, requiredLevel = 10, mana = 53332 },
	{ key = "BreakfastofDraconicChampions", id = 197763, requiredLevel = 10, mana = 71428 },
	{ key = "DracthyrWaterRations", id = 200305, requiredLevel = 10, mana = 50000 },
	{ key = "'Bottled'Ley-EnrichedWater", id = 140204, requiredLevel = 42, mana = 15000 },
	{ key = "ClefthoofMilk", id = 117475, requiredLevel = 35, mana = 10000 },
	{ key = "FreshWater", id = 58274, requiredLevel = 27, mana = 0, manaPercent = 3, manaDuration = 20 },
	{ key = "CoboCola", id = 81923, requiredLevel = 35, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "BubblingWater", id = 9451, requiredLevel = 7, mana = 576 },
	{ key = "FizzyFaireDrink", id = 19299, requiredLevel = 7, mana = 576 },
	{ key = "Free-RangeGoat'sMilk", id = 159868, requiredLevel = 35, mana = 12000 },
	{ key = "AmbroriaDew", id = 177040, requiredLevel = 55, mana = 56 },
	{ key = "FrozenSolidTea", id = 202315, requiredLevel = 10, mana = 62500 },
	{ key = "CranialConcoction", id = 178542, requiredLevel = 50, mana = 37500 },
	{ key = "ChilledConjuredWater", id = 128850, requiredLevel = 42, mana = 15000 },
	{ key = "EmeraldGreenApple", id = 201469, requiredLevel = 10, mana = 53332 },
	{ key = "FilteredGloomwater", id = 163786, requiredLevel = 35, mana = 18000 },
	{ key = "Bottled-CarbonatedWater", id = 140340, requiredLevel = 32, mana = 8 },
	{ key = "CorpiniSlurry", id = 178534, requiredLevel = 50, mana = 37500 },
	{ key = "DosOgris", id = 32668, requiredLevel = 27, mana = 9918 },
	{ key = "FungusSqueezings", id = 59230, requiredLevel = 30, mana = 10980 },
	{ key = "Flappuccino", id = 201725, requiredLevel = 10, mana = 62500 },
	{ key = "DreamwardingDripbrew", id = 201046, requiredLevel = 10, mana = 62500 },
	{ key = "DistilledFishJuice", id = 194692, requiredLevel = 10, mana = 50000 },
	{ key = "Enhancement-FreeWater", id = 169120, requiredLevel = 45, mana = 12000 },
	{ key = "EnhancedWater", id = 169119, requiredLevel = 45, mana = 12000 },
	{ key = "FunkyMonkeyBrew", id = 105711, requiredLevel = 32, mana = 9000 },
	{ key = "ArgaliMilk", id = 195459, requiredLevel = 10, mana = 50000 },
	{ key = "BlendedBeanBrew", id = 17404, requiredLevel = 3, mana = 1008 },
	{ key = "BottledStillwater", id = 155909, requiredLevel = 7, mana = 576 },
	{ key = "'Natural'HighmountainSpringWater", id = 140203, requiredLevel = 37, mana = 10000 },
	{ key = "Barter-B-Q", id = 205690, requiredLevel = 65, mana = 53332 },
	{ key = "ArcanostabilizedProvisions", id = 201047, requiredLevel = 10, mana = 53332 },
	{ key = "BottledWinterspringWater", id = 19300, requiredLevel = 15, mana = 1800 },
	{ key = "EnrichedMannaBiscuit", id = 13724, requiredLevel = 20, mana = 240901 },
	{ key = "CatalyzedApplePie", id = 190880, requiredLevel = 55, mana = 56 },
	{ key = "Cupo'Wakeup", id = 197856, requiredLevel = 10, mana = 62500 },
	{ key = "CircleofSubsistence", id = 190881, requiredLevel = 55, mana = 56 },
	{ key = "Crusader'sWaterskin", id = 42777, requiredLevel = 27, mana = 21258 },
	{ key = "BlackrockFortifiedWater", id = 38431, requiredLevel = 27, mana = 9918 },
	{ key = "BiscuitsandCaviar", id = 172046, requiredLevel = 50, mana = 16 },
	{ key = "Freeze-DriedHyenaJerky", id = 98116, requiredLevel = 32, mana = 7320 },
	{ key = "Buttermilk", id = 194683, requiredLevel = 10, mana = 62500 },
	{ key = "FreshAppleJuice", id = 43086, requiredLevel = 25, mana = 10704 },
	{ key = "DrustvarDarkRoast", id = 163101, requiredLevel = 35, mana = 12000 },
	{ key = "AcornMilk", id = 196584, requiredLevel = 10, mana = 50000 },
	{ key = "Elemental-DistilledWater", id = 128385, requiredLevel = 35, mana = 10000 },
	{ key = "BlackCoffee", id = 33042, requiredLevel = 27, mana = 9918 },
	{ key = "BioluminescentOceanPunch", id = 169949, requiredLevel = 45, mana = 18000 },
	{ key = "BlackrockMineralWater", id = 38430, requiredLevel = 25, mana = 10704 },
	{ key = "BlackDragonRedEye", id = 201698, requiredLevel = 10, mana = 62500 },
	{ key = "FrenzyandChips", id = 195466, requiredLevel = 10, mana = 53332 },
	{ key = "EnrichedTeroconeJuice", id = 32722, requiredLevel = 26, mana = 10704 },
	{ key = "EmpyreanFruitSalad", id = 174284, requiredLevel = 55, mana = 56 },
	{ key = "ColdarraColdbrew", id = 201697, requiredLevel = 10, mana = 62500 },
	{ key = "DriedMackerelStrips", id = 133575, requiredLevel = 40, mana = 16 },
	{ key = "Eternity-InfusedBurrata", id = 201413, requiredLevel = 10, mana = 53332 },
	{ key = "AzuremystWaterFlask", id = 152717, requiredLevel = 45, mana = 15000 },
	{ key = "FeastoftheFishes", id = 152564, requiredLevel = 1, mana = 9615 },
	{ key = "FilteredDraenicWater", id = 28399, requiredLevel = 10, mana = 0, manaPercent = 2, manaDuration = 20 },
	{ key = "FilteredZanj'irWater", id = 169948, requiredLevel = 45, mana = 12000 },
	{ key = "BeetleJuice", id = 178538, requiredLevel = 50, mana = 37500 },
	{ key = "BottledMaelstrom", id = 140629, requiredLevel = 42, mana = 15000 },
	{ key = "BoneAppleTea", id = 178545, requiredLevel = 55, mana = 56 },
	{ key = "AzurebloomTea", id = 178217, requiredLevel = 55, mana = 56 },
	{ key = "EtherealPomegranate", id = 173859, requiredLevel = 55, mana = 56 },
	{ key = "Fresh-SqueezedLimeade", id = 44941, requiredLevel = 25, mana = 10704 },
	{ key = "ArtisanalBerryJuice", id = 194691, requiredLevel = 10, mana = 50000 },
	{ key = "CandiedAmberjackCakes", id = 172047, requiredLevel = 55, mana = 56 },
	{ key = "BlackTea", id = 90660, requiredLevel = 7, mana = 576 },
	{ key = "DragonspringWater", id = 194685, requiredLevel = 10, mana = 62500 },
	{ key = "CanteenofRivermarshRainwater", id = 163785, requiredLevel = 25, mana = 18000 },
	{ key = "FriedTurtleBits", id = 158926, requiredLevel = 45, mana = 12 },
	{ key = "BlackrockSpringWater", id = 38429, requiredLevel = 20, mana = 4050 },
	{ key = "BitterPlasma", id = 38698, requiredLevel = 25, mana = 10704 },
	{ key = "EarlBlackTea", id = 49602, requiredLevel = 3, mana = 1008 },
	{ key = "FrostberryJuice", id = 37253, requiredLevel = 27, mana = 9918 },
	{ key = "EnchantedWater", id = 4791, requiredLevel = 11, mana = 5 },
	{ key = "FlaskofArdendew", id = 173762, requiredLevel = 50, mana = 37500 },
	{ key = "CarbonatedWater", id = 81924, requiredLevel = 32, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "ArcberryJuice", id = 141215, requiredLevel = 42, mana = 10000 },
	{ key = "AncientFirewine", id = 197849, requiredLevel = 10, mana = 50000 },
	{ key = "Ethermead", id = 29395, requiredLevel = 27, mana = 9918 },
	{ key = "YetiMilk", id = 41731, requiredLevel = 27, mana = 21258 },
	{ key = "WellWater", id = 60269, requiredLevel = 0, mana = 360 },
	{ key = "VolcanicSpringWater", id = 49601, requiredLevel = 3, mana = 1008 },
	{ key = "ViseclawSoup", id = 85501, requiredLevel = 32, mana = 8 },
	{ key = "VoidPort", id = 260293, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "VoidwyrmAbsinthe", id = 260294, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "Underjelly", id = 139347, requiredLevel = 42, mana = 15000 },
	{ key = "TwilightTea", id = 186704, requiredLevel = 55, mana = 56 },
	{ key = "KaldoreiFruitcake", id = 204235, requiredLevel = 65, mana = 53332 },
	{ key = "HoneySnack", id = 198356, requiredLevel = 10, mana = 53332 },
	{ key = "SilithusSwiss", id = 201820, requiredLevel = 10, mana = 53332 },
	{ key = "SugarwingCupcake", id = 194681, requiredLevel = 10, mana = 53332 },
	{ key = "GinsengTea", id = 75026, requiredLevel = 32, mana = 7320 },
	{ key = "GilneasSparklingWater", id = 30457, requiredLevel = 27, mana = 9918 },
	{ key = "Gnolan'sHouseSpecial", id = 201420, requiredLevel = 65, mana = 53332 },
	{ key = "GoldenCarpConsomme", id = 74636, requiredLevel = 32, mana = 16 },
	{ key = "GoldthornTea", id = 10841, requiredLevel = 11, mana = 5 },
	{ key = "GorgrondMineralWater", id = 117452, requiredLevel = 35, mana = 10000 },
	{ key = "Graccu'sMinceMeatFruitcake", id = 21215, requiredLevel = 17, mana = 300000 },
	{ key = "GreasyWhaleMilk", id = 59029, requiredLevel = 30, mana = 10980 },
	{ key = "GrilledBonescale", id = 34760, requiredLevel = 27, mana = 9066 },
	{ key = "GrilledCatfish", id = 154889, requiredLevel = 45, mana = 12 },
	{ key = "GrizzleberryJuice", id = 40357, requiredLevel = 27, mana = 9918 },
	{ key = "HeartsbaneHexwurst", id = 163781, requiredLevel = 45, mana = 17 },
	{ key = "HeartySquashStew", id = 197848, requiredLevel = 10, mana = 53332 },
	{ key = "HighlandSpringWater", id = 58257, requiredLevel = 32, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "HighmountainRunoff", id = 138975, requiredLevel = 37, mana = 10000 },
	{ key = "HighmountainSpringWater", id = 128853, requiredLevel = 30, mana = 10000 },
	{ key = "HoneymintTea", id = 33445, requiredLevel = 35, mana = 0, manaPercent = 3, manaDuration = 20 },
	{ key = "Horno'Mead", id = 194690, requiredLevel = 10, mana = 50000 },
	{ key = "HotButteredTrout", id = 33053, requiredLevel = 26, mana = 5508 },
	{ key = "HyjalNectar", id = 18300, requiredLevel = 23, mana = 7560 },
	{ key = "IceColdMilk", id = 1179, requiredLevel = 3, mana = 0, manaPercent = 1, manaDuration = 20 },
	{ key = "IcedHighmountainRefresher", id = 140269, requiredLevel = 42, mana = 15000 },
	{ key = "IllidariWaterskin", id = 133586, requiredLevel = 35, mana = 10000 },
	{ key = "InfusedMuckWater", id = 179993, requiredLevel = 50, mana = 37500 },
	{ key = "InvigoratingPineapplePunch", id = 68140, requiredLevel = 32, mana = 13500 },
	{ key = "IronHordeRations", id = 112449, requiredLevel = 10, mana = 9000 },
	{ key = "JadeWitchBrew", id = 75037, requiredLevel = 33, mana = 8 },
	{ key = "JasmineTea", id = 90659, requiredLevel = 3, mana = 1008 },
	{ key = "JerkySurprise", id = 194680, requiredLevel = 10, mana = 53332 },
	{ key = "K'Bab", id = 174351, requiredLevel = 0, mana = 23077 },
	{ key = "K.R.E.", id = 98111, requiredLevel = 32, mana = 7320 },
	{ key = "KafaKicker", id = 140266, requiredLevel = 42, mana = 15000 },
	{ key = "Kungaloosh", id = 39520, requiredLevel = 26, mana = 18 },
	{ key = "Kurd'sSoftServe", id = 138983, requiredLevel = 42, mana = 16 },
	{ key = "KurdosYogurt", id = 138986, requiredLevel = 42, mana = 16 },
	{ key = "LadenApple", id = 140355, requiredLevel = 35, mana = 16 },
	{ key = "LegendermainyLightRoast", id = 140265, requiredLevel = 42, mana = 15000 },
	{ key = "LemonFlowerPudding", id = 108920, requiredLevel = 35, mana = 9000 },
	{ key = "Ley-EnrichedWater", id = 138292, requiredLevel = 40, mana = 15000 },
	{ key = "LifeFireLatte", id = 201721, requiredLevel = 10, mana = 62500 },
	{ key = "LotusWater", id = 88532, requiredLevel = 32, mana = 16 },
	{ key = "LukewarmTauralusMilk", id = 178539, requiredLevel = 55, mana = 56 },
	{ key = "MadBrewer'sBreakfast", id = 75038, requiredLevel = 35, mana = 4500 },
	{ key = "MagicTruffle", id = 162012, requiredLevel = 1, mana = 15000 },
	{ key = "Mananelle'sSparklingCider", id = 140298, requiredLevel = 42, mana = 10000 },
	{ key = "Mei'sMasterfulBrew", id = 63251, requiredLevel = 32, mana = 13500 },
	{ key = "MelonJuice", id = 1205, requiredLevel = 7, mana = 0, manaPercent = 1, manaDuration = 20 },
	{ key = "MoonberryJuice", id = 1645, requiredLevel = 15, mana = 0, manaPercent = 2, manaDuration = 20 },
	{ key = "MorningGloryDew", id = 8766, requiredLevel = 10, mana = 0, manaPercent = 2, manaDuration = 20 },
	{ key = "MountMugambaSpringWater", id = 163783, requiredLevel = 10, mana = 12000 },
	{ key = "MountainWater", id = 44750, requiredLevel = 27, mana = 9918 },
	{ key = "MurkyCavewater", id = 133980, requiredLevel = 40, mana = 24000 },
	{ key = "MurkyWater", id = 59229, requiredLevel = 27, mana = 21258 },
	{ key = "PailofWarmMilk", id = 138982, requiredLevel = 42, mana = 15000 },
	{ key = "PantLoaf", id = 139398, requiredLevel = 40, mana = 16 },
	{ key = "PerfectlyCookedInstantNoodles", id = 86026, requiredLevel = 31, mana = 7320 },
	{ key = "PotatoAxebeakStew", id = 130192, requiredLevel = 35, mana = 6000 },
	{ key = "PricklevineJuice", id = 162570, requiredLevel = 25, mana = 18000 },
	{ key = "PungentSealWhey", id = 33444, requiredLevel = 25, mana = 0, manaPercent = 3, manaDuration = 20 },
	{ key = "PurifiedDraenicWater", id = 27860, requiredLevel = 10, mana = 9918 },
	{ key = "PurifiedSkyspringWater", id = 174281, requiredLevel = 50, mana = 37500 },
	{ key = "RawNazmaniMineralWater", id = 162547, requiredLevel = 45, mana = 12000 },
	{ key = "RefreshingPineapplePunch", id = 63530, requiredLevel = 3, mana = 1008 },
	{ key = "RestorativeFlow", id = 190936, requiredLevel = 55, mana = 56 },
	{ key = "RockskipMineralWater", id = 159867, requiredLevel = 10, mana = 18000 },
	{ key = "SaberfishBroth", id = 111455, requiredLevel = 35, mana = 16 },
	{ key = "SableSoup", id = 187911, requiredLevel = 50, mana = 37500 },
	{ key = "Sailor'sChoiceCoffee", id = 163104, requiredLevel = 25, mana = 12000 },
	{ key = "SasparillaSinker", id = 74822, requiredLevel = 32, mana = 13500 },
	{ key = "SauteedGoby", id = 34761, requiredLevel = 27, mana = 9066 },
	{ key = "ScaldingMurglesnout", id = 68687, requiredLevel = 30, mana = 3828 },
	{ key = "ScorpionCrunchies", id = 98118, requiredLevel = 32, mana = 7320 },
	{ key = "ScrollofSubsistence", id = 163692, requiredLevel = 35, mana = 18000 },
	{ key = "SeaSaltJava", id = 169952, requiredLevel = 45, mana = 18000 },
	{ key = "SeafoamCoconutWater", id = 163784, requiredLevel = 25, mana = 18000 },
	{ key = "SeasonedLoins", id = 154891, requiredLevel = 45, mana = 20 },
	{ key = "ShadespringWater", id = 179992, requiredLevel = 55, mana = 56 },
	{ key = "Silverwine", id = 29454, requiredLevel = 25, mana = 10704 },
	{ key = "SkinnyMilk", id = 138981, requiredLevel = 37, mana = 10000 },
	{ key = "SkullfishSoup", id = 33825, requiredLevel = 27, mana = 9918 },
	{ key = "SlightlyRustedCanteen", id = 141527, requiredLevel = 37, mana = 10000 },
	{ key = "SlushyWater", id = 184201, requiredLevel = 50, mana = 37500 },
	{ key = "SmallFeast", id = 43480, requiredLevel = 27, mana = 9066 },
	{ key = "SmokedRockfin", id = 34759, requiredLevel = 27, mana = 9066 },
	{ key = "SouthIslandIcedTea", id = 62672, requiredLevel = 30, mana = 18 },
	{ key = "SparklingOasisWater", id = 58256, requiredLevel = 30, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "SparklingSouthshoreCider", id = 29401, requiredLevel = 27, mana = 9918 },
	{ key = "SpoiledFirewine", id = 201813, requiredLevel = 10, mana = 50000 },
	{ key = "Star'sLament", id = 32455, requiredLevel = 23, mana = 7560 },
	{ key = "Star'sSorrow", id = 43236, requiredLevel = 27, mana = 21258 },
	{ key = "Star'sTears", id = 32453, requiredLevel = 27, mana = 9918 },
	{ key = "StarfireEspresso", id = 62675, requiredLevel = 30, mana = 8160 },
	{ key = "StarhookSpecialBlend", id = 163102, requiredLevel = 10, mana = 12000 },
	{ key = "SteamedScarabSteak", id = 200871, requiredLevel = 10, mana = 53332 },
	{ key = "SteepedKelpTea", id = 169954, requiredLevel = 45, mana = 18000 },
	{ key = "StellaviatoriSoup", id = 205692, requiredLevel = 65, mana = 53332 },
	{ key = "Sun-ParchedWaterskin", id = 162569, requiredLevel = 10, mana = 12000 },
	{ key = "SuramarSpicedTea", id = 140272, requiredLevel = 42, mana = 15000 },
	{ key = "SweetandSourClamChowder", id = 197762, requiredLevel = 10, mana = 71428 },
	{ key = "SweetNectar", id = 1708, requiredLevel = 11, mana = 0, manaPercent = 1, manaDuration = 20 },
	{ key = "SweetenedGoat'sMilk", id = 35954, requiredLevel = 10, mana = 9918 },
	{ key = "SwogSlurp", id = 197857, requiredLevel = 10, mana = 50000 },
	{ key = "Syrup-DrenchedToast", id = 196582, requiredLevel = 10, mana = 53332 },
	{ key = "TarpCollectedDew", id = 49254, requiredLevel = 1, mana = 360 },
	{ key = "ThunderspineNest", id = 207956, requiredLevel = 65, mana = 53332 },
	{ key = "ThunderspineTenders", id = 198441, requiredLevel = 10, mana = 53332 },
	{ key = "Thuni'sPatentedDrinkingFluid", id = 139346, requiredLevel = 37, mana = 10000 },
	{ key = "TimelessTea", id = 104348, requiredLevel = 32, mana = 9000 },
	{ key = "ZestyWater", id = 197770, requiredLevel = 60, mana = 120000 },
	{ key = "CinderNectar", id = 222744, requiredLevel = 68, mana = 53572 },
	{ key = "Pep-In-Your-Step", id = 222745, requiredLevel = 68, mana = 53572 },
	{ key = "Magmalaid", id = 227310, requiredLevel = 70, mana = 32000 },
	{ key = "Titanshake", id = 227309, requiredLevel = 70, mana = 32000 },
	{ key = "QuicksilverSipper", id = 227318, requiredLevel = 75, mana = 40000 },
	{ key = "LavaCola", id = 227317, requiredLevel = 75, mana = 40000 },
	{ key = "ChalcociteLavaCake", id = 227326, requiredLevel = 75, mana = 30000 },
	{ key = "StoneSoup", id = 227325, requiredLevel = 75, mana = 30000 },
	{ key = "RockyRoad", id = 227327, requiredLevel = 75, mana = 30000 },
	{ key = "TarragonSoda", id = 227315, requiredLevel = 70, mana = 32000 },
	{ key = "Eggnog", id = 227316, requiredLevel = 70, mana = 32000 },
	{ key = "Nerub'arNectar", id = 227324, requiredLevel = 75, mana = 40000 },
	{ key = "MushroomTea", id = 227323, requiredLevel = 75, mana = 40000 },
	{ key = "MoleMole", id = 227334, requiredLevel = 75, mana = 30000 },
	{ key = "BorerBloodPudding", id = 227335, requiredLevel = 75, mana = 30000 },
	{ key = "SugarSlurry", id = 227336, requiredLevel = 75, mana = 30000 },
	{ key = "GallagioEspecial", id = 236646, requiredLevel = 75, mana = 30000 },
	{ key = "GlimmeringDelicacy", id = 227333, requiredLevel = 75, mana = 30000 },
	{ key = "ImitationCrabMeat", id = 236680, requiredLevel = 75, mana = 30000 },
	{ key = "Paincracker", id = 236650, requiredLevel = 75, mana = 30000 },
	{ key = "CoinandKaja", id = 236647, requiredLevel = 75, mana = 30000 },
	{ key = "Low-TownFizz", id = 236633, requiredLevel = 75, mana = 30000 },
	{ key = "LiquidGold", id = 236681, requiredLevel = 75, mana = 30000 },
	{ key = "LiquidNitro", id = 236648, requiredLevel = 75, mana = 30000 },
	{ key = "FewScrewsLoose", id = 236649, requiredLevel = 75, mana = 30000 },
	{ key = "SippingAether", id = 227332, requiredLevel = 75, mana = 30000 },
	{ key = "Afterglow", id = 227312, requiredLevel = 70, mana = 32000 },
	{ key = "BlessedBrew", id = 227321, requiredLevel = 75, mana = 40000 },
	{ key = "CherryBombs", id = 232376, requiredLevel = 60, mana = 50000 },
	{ key = "CoagulatedMilkProtein", id = 247699, requiredLevel = 75, mana = 30000 },
	{ key = "Coffee,LightIce", id = 227314, requiredLevel = 70, mana = 32000 },
	{ key = "Deep-FiredDevourerLegs", id = 247698, requiredLevel = 75, mana = 30000 },
	{ key = "Delver'sWaterskin", id = 224762, requiredLevel = 75, mana = 32000 },
	{ key = "Digspresso", id = 227311, requiredLevel = 70, mana = 32000 },
	{ key = "PurifiedCordial", id = 260258, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "EverspringWater", id = 260259, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "SpringrunnerSparkling", id = 260260, requiredLevel = 85, mana = 0, manaPercent = 5, manaDuration = 20 },
	{ key = "FairbreezeFeast", id = 260262, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "SilvermoonSoireeSpread", id = 260263, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "BloomNectar", id = 260261, requiredLevel = 85, mana = 0, manaPercent = 5, manaDuration = 20 },
	{ key = "QuelDanasRations", id = 260264, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "DarkwellDraft", id = 264984, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "Dawnmosa", id = 264985, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "MagistersMead", id = 264987, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "SunwellShot", id = 264983, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "DragonhawkFlight", id = 264989, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "MidnightRefreshment260282", id = 260282, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "MidnightRefreshment260283", id = 260283, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "MidnightRefreshment260284", id = 260284, requiredLevel = 85, mana = 0, manaPercent = 5, manaDuration = 20 },
	{ key = "MidnightRefreshment260285", id = 260285, requiredLevel = 85, mana = 0, manaPercent = 5, manaDuration = 20 },
	{ key = "MidnightRefreshment260286", id = 260286, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20, sortRank = 1 },
	{ key = "MidnightRefreshment260287", id = 260287, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20, sortRank = 1 },
	{ key = "MidnightRefreshment260288", id = 260288, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20, sortRank = 1 },
	{ key = "ArgentleafTea", id = 242298, requiredLevel = 80, mana = 0, manaPercent = 8, manaDuration = 20 },
	{ key = "AzerootTea", id = 242301, requiredLevel = 80, mana = 0, manaPercent = 8, manaDuration = 20 },
	{ key = "ManaLilyTea", id = 242297, requiredLevel = 80, mana = 0, manaPercent = 8, manaDuration = 20 },
	{ key = "SanguithornTea", id = 242299, requiredLevel = 80, mana = 0, manaPercent = 8, manaDuration = 20 },
	{ key = "TranquilityBloomTea", id = 242300, requiredLevel = 80, mana = 0, manaPercent = 8, manaDuration = 20 },
	{ key = "RiverpawTeaLeaf", id = 1401, requiredLevel = 2, mana = 231 },
	{ key = "ConjuredPurifiedWater", id = 2136, requiredLevel = 7, mana = 576 },
	{ key = "ConjuredFreshWater", id = 2288, requiredLevel = 3, mana = 1008 },
	{ key = "ConjuredSpringWater", id = 3772, requiredLevel = 11, mana = 5 },
	{ key = "ConjuredWater", id = 5350, requiredLevel = 1, mana = 360 },
	{ key = "ConjuredMineralWater", id = 8077, requiredLevel = 15, mana = 1800 },
	{ key = "ConjuredSparklingWater", id = 8078, requiredLevel = 20, mana = 4050 },
	{ key = "ConjuredCrystalWater", id = 8079, requiredLevel = 23, mana = 7560 },
	{ key = "AlteracMannaBiscuit", id = 19301, requiredLevel = 22, mana = 180649 },
	{ key = "EssenceMango", id = 20031, requiredLevel = 23, mana = 183894 },
	{ key = "BobbingApple", id = 20516, requiredLevel = 1, mana = 225000 },
	{ key = "ConjuredGlacierWater", id = 22018, requiredLevel = 27, mana = 9918 },
	{ key = "UndersporePod", id = 28112, requiredLevel = 1, mana = 180649 },
	{ key = "ConjuredMountainSpringWater", id = 30703, requiredLevel = 25, mana = 10704 },
	{ key = "ConjuredManaBiscuit", id = 34062, requiredLevel = 26, mana = 9918 },
	{ key = "NaaruRation", id = 34780, requiredLevel = 26, mana = 9918 },
	{ key = "GiganticFeast", id = 43478, requiredLevel = 27, mana = 9066 },
	{ key = "GarrsLimeade", id = 61382, requiredLevel = 1, mana = 8400 },
	{ key = "SweetTea", id = 63023, requiredLevel = 15, mana = 1800 },
	{ key = "StormwindSurprise", id = 75028, requiredLevel = 1, mana = 300000 },
	{ key = "PerpetualLeftovers", id = 87253, requiredLevel = 35, mana = 15000 },
	{ key = "CupofKafa", id = 88578, requiredLevel = 1, mana = 15000 },
	{ key = "FrostboarJerky", id = 111544, requiredLevel = 35, mana = 16 },
	{ key = "TastyTaladorLunch", id = 116120, requiredLevel = 37, mana = 6000 },
	{ key = "BlindPalefish", id = 118424, requiredLevel = 35, mana = 16 },
	{ key = "AncientBandana", id = 130259, requiredLevel = 35, mana = 16 },
	{ key = "Lavacolada", id = 140628, requiredLevel = 37, mana = 10000 },
	{ key = "MardivassMagnificentDesalinatingPouch", id = 169763, requiredLevel = 1, mana = 120000 },
	{ key = "StygianStew", id = 174283, requiredLevel = 55, mana = 56 },
	{ key = "SunwarmedXyfias", id = 177041, requiredLevel = 55, mana = 56 },
	{ key = "FiveChimeBatzos", id = 177042, requiredLevel = 55, mana = 56 },
	{ key = "StitchedSurpriseCake", id = 178515, requiredLevel = 35, mana = 15000 },
	{ key = "SuspiciousSlimeShot", id = 178535, requiredLevel = 55, mana = 56 },
	{ key = "WarmBrewfestPretzel", id = 180006, requiredLevel = 10, mana = 89600 },
	{ key = "StaleBrewfestPretzel", id = 180011, requiredLevel = 10, mana = 12 },
	{ key = "LunarDumplings", id = 180054, requiredLevel = 10, mana = 89600 },
	{ key = "MothersGift", id = 194682, requiredLevel = 10, mana = 53332 },
	{ key = "FermentedMuskenMilk", id = 195460, requiredLevel = 10, mana = 50000 },
	{ key = "SweetenedBroadhoofMilk", id = 195464, requiredLevel = 10, mana = 62500 },
	{ key = "StormwingEggBreakfast", id = 195465, requiredLevel = 10, mana = 53332 },
	{ key = "GrizzlyHillsTrailMix", id = 226262, requiredLevel = 75, mana = 30000 },
	{ key = "GrizzlyHillsSpringWater", id = 226274, requiredLevel = 70, mana = 32000 },
	{ key = "StarfruitPuree", id = 227313, requiredLevel = 70, mana = 32000 },
	{ key = "Koboldchino", id = 227319, requiredLevel = 75, mana = 40000 },
	{ key = "WickerWisps", id = 227320, requiredLevel = 75, mana = 40000 },
	{ key = "SanctifiedSasparilla", id = 227322, requiredLevel = 75, mana = 40000 },
	{ key = "WaxFondue", id = 227328, requiredLevel = 75, mana = 30000 },
	{ key = "StillTwitchingGumbo", id = 227329, requiredLevel = 75, mana = 30000 },
	{ key = "GrottochunkStew", id = 227330, requiredLevel = 75, mana = 30000 },
	{ key = "SaintsDelight", id = 227331, requiredLevel = 75, mana = 30000 },
	{ key = "SleuthsSip", id = 232007, requiredLevel = 1, mana = 1008 },
	{ key = "MachosMagnificentFishTacos", id = 238896, requiredLevel = 80, mana = 30000 },
	{ key = "Kafaccino", id = 242693, requiredLevel = 1, mana = 15000 },
	{ key = "SniftedVoidEssence", id = 247694, requiredLevel = 75, mana = 40000 },
	{ key = "SparklingManaSupplement", id = 247695, requiredLevel = 75, mana = 40000 },
	{ key = "PungentSmellingSalts", id = 247696, requiredLevel = 75, mana = 30000 },
	{ key = "GenuineKareshiHoney", id = 247700, requiredLevel = 75, mana = 30000 },
	{ key = "RootJuice", id = 260271, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "CrispBluffBock", id = 260272, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "TeaofMistsandRain", id = 260273, requiredLevel = 85, mana = 0, manaPercent = 5, manaDuration = 20 },
	{ key = "DenshroomDeepRoast", id = 260274, requiredLevel = 85, mana = 0, manaPercent = 5, manaDuration = 20 },
	{ key = "MukleechCurry", id = 260275, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "Akilstew", id = 260276, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "SedgeCrawlerGumbo", id = 260277, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "PurifiedStormWater", id = 260295, requiredLevel = 85, mana = 0, manaPercent = 5, manaDuration = 20 },
	{ key = "ShadeleafTea", id = 260296, requiredLevel = 85, mana = 0, manaPercent = 5, manaDuration = 20 },
	{ key = "VoidfarersRespite", id = 260297, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "AstralApplePie", id = 260298, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "RoastedAbyssalEel", id = 260299, requiredLevel = 90, mana = 0, manaPercent = 7, manaDuration = 20 },
	{ key = "GoldengroveJuice", id = 264981, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "WineNot", id = 264982, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "FairbreezeFranciacorta", id = 264990, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "ConjuredTea", id = 265099, requiredLevel = 80, mana = 0, manaPercent = 6, manaDuration = 20 },
	{ key = "BuddingLight", id = 265664, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "ChanterelleShandy", id = 265665, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "WorldRootBeer", id = 265666, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
	{ key = "BrightClaw", id = 265667, requiredLevel = 80, mana = 0, manaPercent = 4, manaDuration = 20 },
}

-- Curated list of mana potions for use in the Drink macro (combat only)
-- Order reflects preference (highest first)
addon.Drinks.manaPotions = {
	{ key = "LightfusedManaPotion", id = 241300, requiredLevel = 81, mana = 26200 },
	{ key = "LightfusedManaPotion", id = 241301, requiredLevel = 81, mana = 22362 },
	{ key = "AlgariManaPotion3", id = 212241, requiredLevel = 71, mana = 270000 },
	{ key = "AlgariManaPotion2", id = 212240, requiredLevel = 71, mana = 234782 },
	{ key = "AlgariManaPotion1", id = 212239, requiredLevel = 71, mana = 204158 },
	{ key = "SurvivalistsManaPotion", id = 224022, requiredLevel = 0, mana = 0, manaPercent = 20 },
	{ key = "AeratedManaPotion", id = 191384, requiredLevel = 61, mana = 20857 },
	{ key = "AeratedManaPotion", id = 191385, requiredLevel = 61, mana = 23986 },
	{ key = "AeratedManaPotion", id = 191386, requiredLevel = 61, mana = 27584 },
	{ key = "AlchemistsRejuvenation", id = 76094, requiredLevel = 32, mana = 550 },
	{ key = "AncientManaPotion", id = 127835, requiredLevel = 40, mana = 2000 },
	{ key = "AncientRejuvenationPotion", id = 127836, requiredLevel = 40, mana = 1500 },
	{ key = "ArgentManaPotion", id = 43530, requiredLevel = 23, mana = 682 },
	{ key = "AuchenaiManaPotion", id = 32948, requiredLevel = 23, mana = 682 },
	{ key = "BottledNethergonEnergy", id = 32902, requiredLevel = 23, mana = 682 },
	{ key = "CavedwellersDelight", id = 212242, requiredLevel = 71, mana = 153119 },
	{ key = "CavedwellersDelight", id = 212243, requiredLevel = 71, mana = 176086 },
	{ key = "CavedwellersDelight", id = 212244, requiredLevel = 71, mana = 202500 },
	{ key = "CoastalManaPotion", id = 152495, requiredLevel = 40, mana = 2666 },
	{ key = "CoastalRejuvenationPotion", id = 163082, requiredLevel = 40, mana = 2000 },
	{ key = "CrazyAlchemistsPotion", id = 40077, requiredLevel = 27, mana = 933 },
	{ key = "DraenicChanneledManaPotion", id = 109221, requiredLevel = 35, mana = 2550 },
	{ key = "DraenicManaPotion", id = 109222, requiredLevel = 35, mana = 1700 },
	{ key = "DraenicRejuvenationPotion", id = 109226, requiredLevel = 35, mana = 850 },
	{ key = "DraughtofWar", id = 67415, requiredLevel = 30, mana = 400 },
	{ key = "DreamlessSleepPotion", id = 12190, requiredLevel = 15, mana = 366 },
	{ key = "FelManaPotion", id = 31677, requiredLevel = 25, mana = 909 },
	{ key = "GreaterDreamlessSleepPotion", id = 20002, requiredLevel = 23, mana = 1200 },
	{ key = "GreaterManaPotion", id = 6149, requiredLevel = 13, mana = 245 },
	{ key = "IcyManaPotion", id = 40067, requiredLevel = 26, mana = 682 },
	{ key = "IronHordeRejuvenationPotion", id = 113585, requiredLevel = 10, mana = 550 },
	{ key = "LesserManaPotion", id = 3385, requiredLevel = 7, mana = 158 },
	{ key = "LeytorrentPotion", id = 127846, requiredLevel = 40, mana = 3000 },
	{ key = "LuminousBluetail", id = 35287, requiredLevel = 23, mana = 100 },
	{ key = "MadAlchemistsPotion", id = 34440, requiredLevel = 25, mana = 625 },
	{ key = "MajorDreamlessSleepPotion", id = 22836, requiredLevel = 25, mana = 206 },
	{ key = "MajorManaPotion", id = 13444, requiredLevel = 10, mana = 511 },
	{ key = "MajorRejuvenationPotion", id = 18253, requiredLevel = 21, mana = 925 },
	{ key = "ManaPotion", id = 3827, requiredLevel = 10, mana = 100 },
	{ key = "ManaPotionInjector", id = 33093, requiredLevel = 23, mana = 682 },
	{ key = "MasterManaPotion", id = 76098, requiredLevel = 32, mana = 1100 },
	{ key = "MightyRejuvenationPotion", id = 57193, requiredLevel = 30, mana = 400 },
	{ key = "MinorManaPotion", id = 2455, requiredLevel = 3, mana = 120 },
	{ key = "MinorRejuvenationPotion", id = 2456, requiredLevel = 3, mana = 90 },
	{ key = "MysteriousPotion", id = 57099, requiredLevel = 30, mana = 1 },
	{ key = "MythicalManaPotion", id = 57192, requiredLevel = 30, mana = 800 },
	{ key = "PotionofConcentration", id = 57194, requiredLevel = 30, mana = 656 },
	{ key = "PotionofFocus", id = 76092, requiredLevel = 32, mana = 825 },
	{ key = "PotionofFrozenFocus", id = 191363, requiredLevel = 61, mana = 36501 },
	{ key = "PotionofFrozenFocus", id = 191364, requiredLevel = 61, mana = 41976 },
	{ key = "PotionofFrozenFocus", id = 191365, requiredLevel = 61, mana = 48272 },
	{ key = "PotionofReplenishment", id = 152561, requiredLevel = 40, mana = 6014 },
	{ key = "PotionofSacrificialAnima", id = 176811, requiredLevel = 51, mana = 4 },
	{ key = "PotionofSpiritualClarity", id = 171272, requiredLevel = 51, mana = 36000 },
	{ key = "PowerfulRejuvenationPotion", id = 40087, requiredLevel = 27, mana = 733 },
	{ key = "RunicManaInjector", id = 42545, requiredLevel = 27, mana = 956 },
	{ key = "RunicManaPotion", id = 33448, requiredLevel = 27, mana = 956 },
	{ key = "SlumberingSoulSerum", id = 212245, requiredLevel = 71, mana = 283553 },
	{ key = "SlumberingSoulSerum", id = 212246, requiredLevel = 71, mana = 326086 },
	{ key = "SlumberingSoulSerum", id = 212247, requiredLevel = 71, mana = 375000 },
	{ key = "SoulfulManaPotion", id = 180318, requiredLevel = 51, mana = 14400 },
	{ key = "SpiritBerries", id = 140347, requiredLevel = 40, mana = 1999 },
	{ key = "SpiritualManaPotion", id = 171268, requiredLevel = 51, mana = 21600 },
	{ key = "SpiritualRejuvenationPotion", id = 171269, requiredLevel = 51, mana = 9000 },
	{ key = "SuperManaPotion", id = 22832, requiredLevel = 23, mana = 682 },
	{ key = "SuperRejuvenationPotion", id = 22850, requiredLevel = 10, mana = 625 },
	{ key = "SuperiorManaPotion", id = 13443, requiredLevel = 18, mana = 493 },
	{ key = "UnstableManaPotion", id = 28101, requiredLevel = 23, mana = 511 },
	{ key = "WildvinePotion", id = 9144, requiredLevel = 15, mana = 462 },
}

local function getDrinkManaValue(drink, maxMana)
	if not drink then return 0 end
	if drink.isMageFood then return maxMana end
	local percent = tonumber(drink.manaPercent)
	if percent and percent > 0 then
		local duration = tonumber(drink.manaDuration)
		if duration and duration > 0 then return maxMana * (percent * duration / 100) end
		return maxMana * (percent / 100)
	end
	return tonumber(drink.mana) or 0
end

local function refreshDrinkSortKeys(maxMana)
	local list = addon.Drinks and addon.Drinks.drinkList
	if not list then return end
	for i = 1, #list do
		local drink = list[i]
		if drink then drink._eqolSortMana = getDrinkManaValue(drink, maxMana) end
	end
end

local function sortDrinkList(maxMana)
	local drinks = addon.Drinks
	local list = drinks and drinks.drinkList
	if not list then return end
	if drinks._lastSortedMana == maxMana then return end
	refreshDrinkSortKeys(maxMana)
	table.sort(list, function(a, b)
		local manaA = (a and a._eqolSortMana) or 0
		local manaB = (b and b._eqolSortMana) or 0
		if manaA ~= manaB then return manaA > manaB end

		local rankA = tonumber(a and a.sortRank) or 0
		local rankB = tonumber(b and b.sortRank) or 0
		if rankA ~= rankB then return rankA > rankB end

		local levelA = tonumber(a and a.requiredLevel) or 0
		local levelB = tonumber(b and b.requiredLevel) or 0
		if levelA ~= levelB then return levelA > levelB end

		return (tonumber(a and a.id) or 0) < (tonumber(b and b.id) or 0)
	end)
	drinks._lastSortedMana = maxMana
end

local function getSpellDrinkAvailabilityMask()
	local list = addon.Drinks and addon.Drinks.drinkList
	if not list then return 0 end

	local mask = 0
	local bit = 1
	for i = 1, #list do
		local drink = list[i]
		if drink and drink.isSpell then
			if IsSpellInSpellBook(drink.id) then mask = mask + bit end
			bit = bit * 2
		end
	end

	return mask
end

local function isAllowedDrinkCacheCurrent(cache, playerLevel, mana, minManaFoodValue, preferMage, allowRecuperate, unitClass, spellMask)
	return cache
		and cache.playerLevel == playerLevel
		and cache.mana == mana
		and cache.minManaFoodValue == minManaFoodValue
		and cache.preferMage == preferMage
		and cache.allowRecuperate == allowRecuperate
		and cache.unitClass == unitClass
		and cache.spellMask == spellMask
end

local function updateAllowedDrinkCache(cache, playerLevel, mana, minManaFoodValue, preferMage, allowRecuperate, unitClass, spellMask)
	cache.playerLevel = playerLevel
	cache.mana = mana
	cache.minManaFoodValue = minManaFoodValue
	cache.preferMage = preferMage
	cache.allowRecuperate = allowRecuperate
	cache.unitClass = unitClass
	cache.spellMask = spellMask
end

function addon.functions.updateAllowedDrinks()
	-- cache globals as locals
	local db = addon.db
	if not db then return end
	local drinks = addon.Drinks
	if not drinks then return end

	local playerLevel = UnitLevel("player")
	local mana = UnitPowerMax("player", 0)
	if mana <= 0 then return end

	ensureMageFoodMap()
	local minManaFoodValue = tonumber(db.minManaFoodValue) or 50
	local preferMage = db.preferMageFood == true
	local allowRecuperate = db.allowRecuperate == true
	local unitClass = addon.variables and addon.variables.unitClass
	local spellMask = getSpellDrinkAvailabilityMask()
	local cache = drinks._allowedCache or {}
	drinks._allowedCache = cache
	if isAllowedDrinkCacheCurrent(cache, playerLevel, mana, minManaFoodValue, preferMage, allowRecuperate, unitClass, spellMask) then return end

	sortDrinkList(mana)

	local minManaValue = mana * (minManaFoodValue / 100)

	-- Reuse result tables to avoid allocations on refresh.
	local filtered = drinks.filteredDrinks or {}
	wipeTable(filtered)
	drinks.filteredDrinks = filtered

	-- Jewelcrafting gem foods are filtered separately from normal drinks.
	local ignoreGems = true

	-- iterate only once over the master list
	for i = 1, #drinks.drinkList do
		local drink = drinks.drinkList[i]
		local req = drink.requiredLevel
		local dMana = drink._eqolSortMana
		if dMana == nil then dMana = getDrinkManaValue(drink, mana) end
		local isRecuperateDrink = allowRecuperate and drink.id == 1231411 and unitClass ~= "MAGE"
		local isMageRefreshment = drink.id == 190336 and unitClass == "MAGE"
		if req <= playerLevel and (dMana >= minManaValue or isRecuperateDrink or isMageRefreshment) then
			if
				not (isEarthen and not drink.isEarthenFood)
				and not (drink.earthenOnly and not isEarthen)
				and not (drink.earthenOnly and drink.isGem and ignoreGems)
				and not (drink.isHealthOnly and not isRecuperateDrink)
				and not (drink.isSpell and not IsSpellInSpellBook(drink.id))
			then
				local wrapped = wrapDrink(drink)
				if not wrapped then
					-- skip malformed entries
				elseif drink.isMageFood and preferMage then
					tinsert(filtered, 1, wrapped)
				else
					tinsert(filtered, wrapped)
				end
			end
		end
	end

	updateAllowedDrinkCache(cache, playerLevel, mana, minManaFoodValue, preferMage, allowRecuperate, unitClass, spellMask)
end
