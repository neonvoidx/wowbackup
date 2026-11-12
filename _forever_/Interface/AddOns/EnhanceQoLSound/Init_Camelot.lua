local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Sounds = addon.Sounds or {}
addon.Sounds.functions = addon.Sounds.functions or {}
addon.Sounds.variables = addon.Sounds.variables or {}
addon.Sounds.muteConditions = {}
addon.LSounds = addon.LSounds or {} -- Locales for aura

function addon.Sounds.functions.InitDB()
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end
	if addon.functions.CleanupUnavailableSoundSettings then addon.functions.CleanupUnavailableSoundSettings() end
	addon.functions.InitDBValue("keepAudioSynced", false)
	addon.functions.InitDBValue("soundExtraEnabled", false)
	addon.functions.InitDBValue("soundExtraEvents", {})
end

addon.Sounds.extraSoundEvents = {
	-- Add events here to expose them in settings and extra sound playback.
	{ event = "ACHIEVEMENT_EARNED", label = "soundExtraEventAchievementEarned" },
	{ event = "CHAT_MSG_BN_WHISPER", label = "soundExtraEventChatBNWhisper" },
	{ event = "CHAT_MSG_WHISPER", label = "soundExtraEventChatWhisper" },
	{ event = "LFG_PROPOSAL_SHOW", label = "soundExtraEventLFGQueueStatus" },
	{ event = "PLAYER_REGEN_ENABLED", label = "soundExtraEventLeaveCombat" },
	{ event = "PLAYER_REGEN_DISABLED", label = "soundExtraEventEnterCombat" },
	{ event = "LOOT_ITEM_ROLL_WON", label = "soundExtraEventLootRollWon" },
	{ event = "SHOW_LOOT_TOAST_LEGENDARY_LOOTED", label = "soundExtraEventLootLegendary" },
	{ event = "SHOW_LOOT_TOAST_UPGRADE", label = "soundExtraEventLootUpgrade" },
	{ event = "LFG_ROLE_CHECK_SHOW", label = "soundExtraEventRoleCheck" },
	{ event = "START_PLAYER_COUNTDOWN", label = "soundExtraEventPlayerCountdown" },
	{
		event = "UPDATE_PENDING_MAIL",
		label = "soundExtraEventNewMail",
		condition = function() return HasNewMail and HasNewMail() end,
	},
	{ event = "RESURRECT_REQUEST", label = "soundExtraEventResurrect" },
	{ event = "READY_CHECK", label = "soundExtraEventReadyCheck" },
	{ event = "PARTY_INVITE_REQUEST", label = "soundExtraEventPartyInvite" },
	{ event = "GROUP_INVITE_CONFIRMATION", label = "soundExtraEventGroupInviteConfirm" },
	{
		event = "CRAFTINGORDERS_PERSONAL_ORDER_NEW",
		label = "soundExtraEventCraftingOrdersNew",
		registerEvent = { "PLAYER_ENTERING_WORLD", "CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS" },
	},
	{
		event = "CRAFTINGORDERS_PERSONAL_ORDER_REMOVED",
		label = "soundExtraEventCraftingOrdersRemoved",
		registerEvent = { "PLAYER_ENTERING_WORLD", "CRAFTINGORDERS_UPDATE_PERSONAL_ORDER_COUNTS" },
	},
}

addon.Sounds.soundFiles = {
	["class"] = {
		["class_warlock_summon_imp"] = {
			-- 1255429,
			-- 1255430,
			-- 1255431,
			-- 1255432,
			-- 1255433,
			551168,
		},
		["class_warlock_succubus_butt_slap"] = {
			561144,
			1466150,
		},
		["class_warlock_summon_felguard"] = {
			547320,
			547328,
			547335,
			547332,
		},
		["class_warlock_summon_succubus"] = {
			561163,
			561168,
			561157,
			561154,
		},
		["class_warlock_summon"] = {
			2068351,
			2068352,
		},
	},
	["spells"] = {
		["bloodlust"] = {
			568812, -- Bloodlust
			569013, -- Heroism
			569578, -- Timewarp
			569379, -- Timewarp
			568818, -- Timewarp
			569126, -- Timewarp
			568451, -- Timewarp
			4567038, -- Timewarp
			4567040, -- Timewarp
			4567042, -- Timewarp
			1416760, -- Timewarp
			1416761, -- Timewarp
			1416762, -- Timewarp
			4558551, -- Fury of the Aspects
			4558553, -- Fury of the Aspects
			4558555, -- Fury of the Aspects
			4558557, -- Fury of the Aspects
			4558559, -- Fury of the Aspects
			4575217, -- Fury of the Aspects
			4575219, -- Fury of the Aspects
			4575221, -- Fury of the Aspects
		},
	},
	["emotes"] = {
		["train"] = {
			--Orc --
			541239, --Male
			541157, --Female

			--Undead --
			542600, --Male
			542526, --Female

			--Tauren --
			542896, --Male
			542818, --Female

			--Troll --
			543093, --Male
			543085, --Female

			--Blood Elf --
			539203, --Male
			539219, --Female
			1306531, --Male Demon Hunter
			1313588, --Female Demon Hunter

			--Goblin --
			542017, --Male
			541769, --Female

			--Nightborne --
			1732405, --Male
			1732030, --Female

			--Highmountain Tauren --
			1730908, --Male
			1730534, --Female

			--Mag'har Orc --
			1951458, --Male
			1951457, --Female

			--Zandalari Troll --
			1903522, --Male
			1903049, --Female

			--Vulpera --
			3106717, --Male
			3106252, --Female

			--Pandaren --
			630296, --Male Train 01
			630298, --Male Train 02
			636621, --Female

			--Dracthyr --
			4737561, --Male Visage
			4738601, --Male Dragonkin
			4741007, --Female Visage
			4739531, --Female Dragonkin

			--Earthen --
			6021052, -- Female
			6021067, -- Male

			--Human --
			540734, --Male
			540535, --Female

			--Dwarf --
			539881, --Male
			539802, --Female

			--Night Elf --
			540947, --Male
			540870, --Female
			1304872, --Male Demon Hunter
			1316209, --Female Demon Hunter

			--Gnome --
			540275, --Male
			540271, --Female

			--Draenei --
			539730, --Male
			539516, --Female

			--Worgen --
			541601, --Male (Human Form)
			542206, --Male (Worgen Form)
			541463, --Female (Human Form)
			542035, --Female (Worgen Form)

			--Void Elf --
			1733163, --Male
			1732785, --Female

			--Lightforged Draenei --
			1731656, --Male
			1731282, --Female

			--Dark Iron Dwarf --
			1902543, --Male
			1902030, --Female

			--Kul Tiran Human --
			2491898, --Male
			2531204, --Female

			--Mechagnome --
			3107182, --Male
			3107651, --Female
		},
	},
	["professions"] = {
		["skinning"] = {
			-- Soundkit 3781
			567454,
			567494,
			567417,
		},
		["herbalism"] = {
			-- Soundkit 1142
			569824,
			569825,
			569797,
			569818,
		},
		["mining"] = {
			-- Soundkit 1143
			569801,
			569811,
			569792,
			569794,
			569821,
		},
		["alchemy"] = {
			-- Soundkit 1105
			569793,
			569802,
			569812,
		},
	},
	["interface"] = {
		["general"] = {
			["bnetNotificationToast"] = {
				567402, -- Battle.net notification toast
			},
			["changeTab"] = {
				567422,
				567507,
				567433,
			},
			["enterQueue"] = {
				568587,
			},
			["readycheck"] = {
				567478,
			},
			["RAID_WARNING"] = {
				567397,
			},
			["coinsound"] = {
				567428,
			},
			["mailboxopen"] = {
				567440,
			},
			["repair"] = {
				569801,
				569811,
				569792,
				569794,
				569821,
			},
			["summoning_stone"] = {
				-- Soundkit 3136 for loop sound
				568938,
				-- Soundkit 119083 for first Sound on portal open
				1684459,
				1684460,
				1684461,
				1684462,
				1684463,
			},
		},
		["chat"] = {
			["whisper"] = {
				-- Soundkit 3081
				567421,
			},
		},
		["ping"] = {
			["ping_minimap"] = {
				567416,
			},
			["ping_warning"] = {
				5342387,
			},
			["ping_ping"] = {
				5339002,
			},
			["ping_assist"] = {
				5339006,
			},
			["ping_omw"] = {
				5340605,
			},
			["ping_attack"] = {
				5350036,
			},
		},
		["quest"] = {
			["quest_complete"] = {
				-- Soundkit 619
				567439,
			},
		},
		["auctionhouse"] = {
			["open"] = {
				567482,
			},
			["close"] = { 567499 },
		},
	},
	["misc"] = {
		["eating"] = {
			-- Soundkit 45
			567612,
		},
	},
}
