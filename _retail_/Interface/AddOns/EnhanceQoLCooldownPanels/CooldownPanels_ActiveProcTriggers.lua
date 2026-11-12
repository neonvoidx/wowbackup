local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.CooldownPanels = addon.Aura.CooldownPanels or {}
local CooldownPanels = addon.Aura.CooldownPanels

CooldownPanels.activeProcTriggerByItemID = {
	[45490] = {
		effectSpellID = 64742,
		triggerSpellID = 64741,
		duration = 10,
		mode = "simple",
		name = "Pandora's Plea",
		itemName = "Pandora's Plea",
	},
	[156207] = {
		effectSpellID = 64742,
		triggerSpellID = 64741,
		duration = 10,
		mode = "simple",
		name = "Pandora's Plea",
		itemName = "Pandora's Plea",
	},
	[240213] = {
		effectSpellID = 1231217,
		triggerSpellID = 1231221,
		duration = 12,
		mode = "simple",
		name = "Veiling Mana Shroud",
		itemName = "Veiling Mana Shroud",
	},
	[240214] = {
		effectSpellID = 1231665,
		triggerSpellID = 1231664,
		duration = 20,
		mode = "simple",
		name = "Disturbed Sands",
		itemName = "Miniature Reshii Sandgarden",
	},
	[242392] = {
		effectSpellID = 1234996,
		stackTriggerSpellID = 1239221,
		duration = 15,
		stackDuration = 15,
		mode = "stacked",
		name = "Diamantine Voidcore",
		itemName = "Diamantine Voidcore",
	},
	[242395] = {
		effectSpellID = 1234714,
		stackTriggerSpellID = 1239641,
		duration = 10,
		stackDuration = 10,
		mode = "stacked",
		name = "Astral Antenna",
		itemName = "Astral Antenna",
	},
	[245750] = {
		effectSpellID = 1244254,
		stackTriggerSpellID = 1244254,
		duration = 15,
		stackDuration = 15,
		mode = "stacked",
		name = "Void Glass",
		itemName = "Darkmoon Deck: Void",
	},
	[245752] = {
		effectSpellID = 345229,
		triggerSpellID = 345230,
		duration = 20,
		mode = "simple",
		name = "Gladiator's Insignia",
		itemName = "Thalassian Competitor's Insignia of Alacrity",
	},
	[245855] = {
		effectSpellID = 1245001,
		triggerSpellID = 1245025,
		duration = 15,
		mode = "simple",
		name = "Farstrider's Guile",
		itemName = "Darkmoon Deck: Blood",
	},
	[246305] = {
		effectSpellID = 1245001,
		triggerSpellID = 1245025,
		duration = 15,
		mode = "simple",
		name = "Farstrider's Guile",
		itemName = "Darkmoon Dominion: Blood",
	},
	[246307] = {
		effectSpellID = 1244254,
		stackTriggerSpellID = 1244254,
		duration = 15,
		stackDuration = 15,
		mode = "stacked",
		name = "Void Glass",
		itemName = "Darkmoon Dominion: Void",
	},
	[246824] = {
		effectSpellID = 1244007,
		triggerSpellID = 1246543,
		duration = 10,
		mode = "simple",
		name = "Shadowguard's Twisted Harvester",
		itemName = "Shadowguard's Twisted Harvester",
	},
	[246939] = {
		effectSpellID = 1244402,
		triggerSpellID = 1245376,
		duration = 8,
		mode = "simple",
		name = "Arcane Hunter",
		itemName = "Essence-Hunter's Eyeglass",
	},
	[246940] = {
		effectSpellID = 1244405,
		triggerSpellID = 1245397,
		duration = 15,
		mode = "simple",
		name = "Manaforged Aethercell",
		itemName = "Manaforged Aethercell",
	},
	[246947] = {
		effectSpellID = 1244417,
		triggerSpellID = 1247500,
		duration = 10,
		mode = "simple",
		name = "Twisted Mana Sprite",
		itemName = "Twisted Mana Sprite",
	},
	[248583] = {
		effectSpellID = 1247568,
		triggerSpellID = 1247577,
		duration = 12,
		mode = "simple",
		name = "Akil'zon's Clarity",
		itemName = "Drum of Renewed Bonds",
	},
	[249341] = {
		effectSpellID = 1258535,
		stackTriggerSpellID = 1258535,
		duration = 12,
		stackDuration = 12,
		mode = "stacked",
		name = "Volatile Void Suffuser",
		itemName = "Volatile Void Suffuser",
	},
	[249342] = {
		effectSpellID = 1251822,
		triggerSpellID = 1262753,
		duration = 12,
		mode = "simple",
		name = "Heart of Ancient Hunger",
		itemName = "Heart of Ancient Hunger",
	},
	[249343] = {
		effectSpellID = 1256896,
		stackTriggerSpellID = 1266687,
		duration = 12,
		stackDuration = 12,
		mode = "stacked",
		name = "Alnscorned Essence",
		itemName = "Gaze of the Alnseer",
	},
	[249809] = {
		effectSpellID = 1259314,
		triggerSpellID = 1259317,
		duration = 10,
		mode = "simple",
		name = "Riftwalker's Temptation",
		itemName = "Locus-Walker's Ribbon",
	},
	[250228] = {
		effectSpellID = 1250564,
		startTriggerSpellID = 1254180,
		stackTriggerSpellID = 1254331,
		duration = 30,
		stackDuration = 8,
		mode = "stackedAfterStart",
		name = "Echoing Roar",
		itemName = "Resonant Bellowstone",
	},
	[250229] = {
		effectSpellID = 1250567,
		triggerSpellID = 1258223,
		duration = 15,
		mode = "simple",
		name = "Nalorakk's Rage",
		itemName = "Idol of the War Loa",
	},
	[250256] = {
		effectSpellID = 1250599,
		triggerSpellID = 1263318,
		duration = 10,
		mode = "simple",
		name = "The Wind Awoken",
		itemName = "Heart of Wind",
	},
	[250259] = {
		effectSpellID = 1250604,
		triggerSpellID = 1263077,
		duration = 15,
		mode = "simple",
		name = "Uprooted Lasher",
		itemName = "Sapling of the Dawnroot",
	},
	[251782] = {
		effectSpellID = 1253110,
		triggerSpellID = 1255226,
		duration = 10,
		mode = "simple",
		name = "Withered Saptor's Paw",
		itemName = "Withered Saptor's Paw",
	},
	[251788] = {
		effectSpellID = 1253116,
		triggerSpellID = 1259228,
		duration = 10,
		mode = "simple",
		name = "Gift of Light",
		itemName = "Gift of Light",
	},
	[251792] = {
		effectSpellID = 1253120,
		triggerSpellID = 1266299,
		duration = 15,
		mode = "simple",
		name = "Fanatical Inspiration",
		itemName = "Glorious Crusader's Keepsake",
	},
	[251883] = {
		effectSpellID = 1253327,
		triggerSpellID = 1253325,
		duration = 10,
		mode = "simple",
		name = "Looming Darkness",
		itemName = "Umbric's Channeling Focus",
	},
	[252420] = {
		effectSpellID = 1254640,
		triggerSpellID = 1255504,
		duration = 10,
		mode = "simple",
		name = "Solarflare Prism",
		itemName = "Solarflare Prism",
	},
	[255328] = {
		effectSpellID = 345229,
		triggerSpellID = 345230,
		duration = 20,
		mode = "simple",
		name = "Gladiator's Insignia",
		itemName = "Galactic Aspirant's Insignia of Alacrity",
	},
	[255614] = {
		effectSpellID = 345229,
		triggerSpellID = 345230,
		duration = 20,
		mode = "simple",
		name = "Gladiator's Insignia",
		itemName = "Galactic Gladiator's Insignia of Alacrity",
	},
	[263282] = {
		effectSpellID = 1270337,
		triggerSpellID = 1270343,
		duration = 15,
		mode = "simple",
		name = "Volatile Power",
		itemName = "Repurposed Volatile Manacell",
	},
	[264968] = {
		effectSpellID = 1272939,
		triggerSpellID = 1272942,
		duration = 10,
		mode = "simple",
		name = "Telluric Leyblossom",
		itemName = "Telluric Leyblossom",
	},
	[265657] = {
		effectSpellID = 1276678,
		triggerSpellID = 1276677,
		duration = 15,
		mode = "simple",
		name = "Fiber of Living Agony",
		itemName = "Fiber of Living Agony",
	},
	[267469] = {
		effectSpellID = 345229,
		triggerSpellID = 345230,
		duration = 20,
		mode = "simple",
		name = "Gladiator's Insignia",
		itemName = "Novice Combatant's Insignia of Alacrity",
	},
	[268292] = {
		effectSpellID = 1284696,
		triggerSpellID = 1284698,
		duration = 12,
		mode = "simple",
		name = "Sporelord's Mycelium",
		itemName = "Sporelord's Mycelial Insignia",
	},
	[270165] = {
		effectSpellID = 1292065,
		stackTriggerSpellID = 1295582,
		duration = 12,
		stackDuration = 12,
		mode = "stacked",
		name = "Focus of Ula'tek",
		itemName = "Keeper's Seething Core",
	},
	[270174] = {
		effectSpellID = 1295643,
		triggerSpellID = 1295649,
		duration = 12,
		mode = "simple",
		name = "Bolstering Gale",
		itemName = "Idol of the Howling Nexus",
	},
	[270558] = {
		effectSpellID = 345229,
		triggerSpellID = 345230,
		duration = 20,
		mode = "simple",
		name = "Gladiator's Insignia",
		itemName = "Venomous Aspirant's Insignia of Alacrity",
	},
	[270603] = {
		effectSpellID = 345229,
		triggerSpellID = 345230,
		duration = 20,
		mode = "simple",
		name = "Gladiator's Insignia",
		itemName = "Venomous Gladiator's Insignia of Alacrity",
	},
	[274892] = {
		effectSpellID = 1295445,
		triggerSpellID = 1295444,
		duration = 20,
		mode = "simple",
		name = "Resilient Felblood",
		itemName = "Resilient Felblood Vial",
	},
	[274893] = {
		effectSpellID = 1295447,
		triggerSpellID = 1295446,
		duration = 10,
		mode = "simple",
		name = "Klaxid Venom",
		itemName = "Frosty Klaxid Stinger",
	},
	[280097] = {
		effectSpellID = 345229,
		triggerSpellID = 345230,
		duration = 20,
		mode = "simple",
		name = "Gladiator's Insignia",
		itemName = "Venomous Aspirant's Insignia of Alacrity",
	},
}

CooldownPanels.activeProcTriggerBySpellID = {}
for itemID, info in pairs(CooldownPanels.activeProcTriggerByItemID) do
	if CooldownPanels.ForEachActiveProcTriggerSpellID then
		CooldownPanels:ForEachActiveProcTriggerSpellID(info, function(triggerSpellID)
			CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] = CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] or {}
			CooldownPanels.activeProcTriggerBySpellID[triggerSpellID][itemID] = info
		end)
	else
		for _, key in ipairs({ "triggerSpellID", "startTriggerSpellID", "stackTriggerSpellID" }) do
			local triggerSpellID = tonumber(info and info[key])
			if triggerSpellID and triggerSpellID > 0 then
				CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] = CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] or {}
				CooldownPanels.activeProcTriggerBySpellID[triggerSpellID][itemID] = info
			end
		end
		for _, triggerSpellID in ipairs(info.triggerSpellIDs or {}) do
			triggerSpellID = tonumber(triggerSpellID)
			if triggerSpellID and triggerSpellID > 0 then
				CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] = CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] or {}
				CooldownPanels.activeProcTriggerBySpellID[triggerSpellID][itemID] = info
			end
		end
	end
end
