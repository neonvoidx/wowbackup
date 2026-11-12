local _, addon = ...
local Probe = {}
addon.RangeDisplay = Probe

-- Forever range estimates; nominal thresholds are not geometric distances.
-- Item results were tested on attackable targets in and out of combat.
-- Nominal yard thresholds still need calibration across target sizes.
Probe.flavors = {
	forever = {
		build = "1.60.1.70338",
		-- Names from these base IDs resolve to learned ranks in the player's spellbook.
		classes = {
			ROGUE = { crosshair = 1752, melee = { 1752 }, ranged = { 2764 } },
			WARRIOR = { crosshair = 78, melee = { 78 }, ranged = { 100, 355 } },
			HUNTER = { crosshair = 75, melee = { 2973 }, ranged = { 75, 1978 } },
			PALADIN = { crosshair = 2537, melee = { 2537 }, ranged = { 20271, 879 } },
			SHAMAN = { crosshair = 403, melee = { 17364 }, ranged = { 8042, 403 } },
			DRUID = { crosshair = 5176, melee = { 1082, 6807 }, ranged = { 5176, 8921 } },
			MAGE = { crosshair = 116, ranged = { 116, 133, 2136, 5019 } },
			PRIEST = { crosshair = 585, ranged = { 585, 589, 8092, 5019 } },
			WARLOCK = { crosshair = 686, ranged = { 686, 172, 689, 5019 } },
		},
		-- 260829 (nominal 8 yd, combat range) contradicted 8149 (5 yd, interact range).
		-- Excluded until its effective range semantics are independently calibrated.
		checks = {
			{ kind = "item", id = 8149, yards = 5 },
			{ kind = "item", id = 17626, yards = 10 },
			{ kind = "item", id = 1191, yards = 20 },
			{ kind = "item", id = 13289, yards = 25 },
			{ kind = "item", id = 835, yards = 30 },
			{ kind = "item", id = 18904, yards = 35 },
			{ kind = "item", id = 8348, yards = 40 },
		},
	},
	retail = { checks = {} },
	tbc = { checks = {} },
}
