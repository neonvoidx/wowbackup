local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Tooltip = addon.Tooltip or {}
addon.LTooltip = addon.LTooltip or {} -- Locales for MythicPlus
addon.Tooltip.functions = addon.Tooltip.functions or {}
addon.Tooltip.variables = addon.Tooltip.variables or {}

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local function normalizeNumericDropdownValue(key, labels, fallback)
	if not addon.db then return end
	local value = addon.db[key]
	if type(value) == "number" and labels[value] ~= nil then return end
	if type(value) == "string" then
		local numeric = tonumber(value)
		if numeric and labels[numeric] ~= nil then
			addon.db[key] = numeric
			return
		end
		local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
		for index, label in pairs(labels) do
			if trimmed == tostring(label) then
				addon.db[key] = index
				return
			end
		end
	end
	addon.db[key] = fallback
end

local function migrateNumericTooltipDropdowns()
	normalizeNumericDropdownValue("TooltipBuffHideType", { [1] = L["TooltipOFF"] or "OFF", [2] = L["TooltipON"] or "ON" }, 1)
	normalizeNumericDropdownValue("TooltipItemHideType", { [1] = L["TooltipOFF"] or "OFF", [2] = L["TooltipON"] or "ON" }, 1)
	normalizeNumericDropdownValue("TooltipSpellHideType", { [1] = L["TooltipOFF"] or "OFF", [2] = L["TooltipON"] or "ON" }, 1)
	normalizeNumericDropdownValue("TooltipUnitHideType", {
		[1] = _G.NONE or "None",
		[2] = L["Enemies"] or "Enemies",
		[3] = L["Friendly"] or "Friendly",
		[4] = _G.STATUS_TEXT_BOTH or "Both",
	}, 1)
	normalizeNumericDropdownValue("TooltipAnchorType", {
		[1] = _G.DEFAULT or "Default",
		[2] = L["CursorCenter"] or "Centered on Cursor",
		[3] = L["CursorLeft"] or "Left of Cursor",
		[4] = L["CursorRight"] or "Right of Cursor",
	}, 1)
end

function addon.Tooltip.functions.InitDB()
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end
	local init = addon.functions.InitDBValue
	init("TooltipAnchorType", 1)
	init("TooltipAnchorOffsetX", 0)
	init("TooltipAnchorOffsetY", 0)
	init("TooltipHideOverrideEnabled", false)
	init("TooltipHideOverrideModifier", "CTRL")
	init("TooltipIDRequireModifier", false)
	init("TooltipIDModifier", "ALT")

	init("TooltipUnitHideType", 1)
	init("TooltipUnitHideInCombat", false)
	init("TooltipUnitHideInDungeon", false)
	init("TooltipUnitHideHealthBar", false)
	init("TooltipShowMythicScore", false)
	init("TooltipMythicScoreRequireModifier", false)
	init("TooltipMythicScoreModifier", "SHIFT")
	-- Mythic+ tooltip details selection (multiselect)
	-- Keys: score (overall score), best (best run), dungeons (all season dungeons)
	init("TooltipMythicScoreParts", { score = true, best = true, dungeons = true })
	init("TooltipShowClassColor", false)
	init("TooltipShowNPCID", false)
	init("TooltipShowNPCWowheadLink", false)
	-- Unit inspect extras
	init("TooltipUnitShowSpec", false)
	init("TooltipUnitShowItemLevel", false)
	-- Gate spec/ilvl lines behind a modifier (uses same modifier as Mythic+ when enabled)
	init("TooltipUnitInspectRequireModifier", false)
	init("TooltipUnitHideRightClickInstruction", false)
	init("TooltipUnitShowTargetOfTarget", false)
	init("TooltipUnitShowMount", false)
	init("TooltipShowRealmInfo", false)
	init("TooltipRealmShowLanguage", true)
	init("TooltipRealmShowType", true)
	init("TooltipRealmShowTimezone", false)
	init("TooltipRealmShowConnected", true)
	init("TooltipRealmInfoFields", { language = true, type = true, connected = true })
	init("TooltipRealmLFGDisplay", { tooltip = true, listingFlag = true })

	-- Spell
	init("TooltipSpellHideType", 1)
	init("TooltipSpellHideInCombat", false)
	init("TooltipSpellHideInDungeon", false)
	init("TooltipShowSpellID", false)

	-- Item
	init("TooltipItemHideType", 1)
	init("TooltipItemHideInCombat", false)
	init("TooltipItemHideInDungeon", false)
	init("TooltipShowItemID", false)
	init("TooltipHousingAutoPreview", false)
	init("TooltipShowItemIcon", false)
	init("TooltipItemIconSize", 16)
	init("TooltipShowGuildRank", false)
	init("TooltipGuildRankColor", { r = 1, g = 1, b = 1 })
	init("TooltipColorGuildName", false)
	init("TooltipGuildNameColor", { r = 0.11, g = 1, b = 0.11 }) -- Blizzard guild green
	init("TooltipHideFaction", false)
	init("TooltipHidePVP", false)
	init("TooltipShowSpellIconInline", false)

	-- Quest
	init("TooltipShowQuestIDInQuestLog", false)

	-- Buff
	init("TooltipBuffHideType", 1)
	init("TooltipBuffHideInCombat", false)
	init("TooltipBuffHideInDungeon", false)

	-- Currency
	init("TooltipShowCurrencyAccountWide", false)
	init("TooltipShowCurrencyID", false)

	migrateNumericTooltipDropdowns()
end

addon.Tooltip.variables.maxLevel = GetMaxLevelForPlayerExpansion()

addon.Tooltip.variables.kindsByID = {
	[0] = "item", -- Item
	[1] = "spell", -- Spell
	[2] = "unit", -- Unit
	[3] = "unit", -- Corpse
	[4] = "object", -- Object
	[5] = "currency", -- Currency
	[6] = "unit", -- BattlePet
	[7] = "aura", -- UnitAura
	[8] = "spell", -- AzeriteEssence
	[9] = "unit", -- CompanionPet
	[10] = "mount", -- Mount
	[11] = "", -- PetAction
	[12] = "achievement", -- Achievement
	[13] = "spell", -- EnhancedConduit
	[14] = "set", -- EquipmentSet
	[15] = "", -- InstanceLock
	[16] = "", -- PvPBrawl
	[17] = "spell", -- RecipeRankInfo
	[18] = "spell", -- Totem
	[19] = "item", -- Toy
	[20] = "", -- CorruptionCleanser
	[21] = "", -- MinimapMouseover
	[22] = "", -- Flyout
	[23] = "quest", -- Quest
	[24] = "quest", -- QuestPartyProgress
	[25] = "macro", -- Macro
	[26] = "", -- Debug
}

local challengeMapIDDefaults = {
	[584] = "TBV",
	[585] = "VSA",
	[586] = "DON",
	[587] = "MR",
	[588] = "AOF",
	[542] = "ED",
	[501] = "SV",
	[502] = "COT",
	[505] = "DAWN",
	[503] = "ARAK",
	[525] = "FLOOD",
	[506] = "MEAD",
	[499] = "PSF",
	[504] = "DFC",
	[500] = "ROOK",
	[463] = "DOTI",
	[464] = "DOTI",
	[399] = "RLP",
	[400] = "NO",
	[405] = "BH",
	[402] = "AA",
	[404] = "NELT",
	[401] = "AV",
	[406] = "HOI",
	[403] = "ULD",
	[376] = "NW",
	[379] = "PF",
	[375] = "MISTS",
	[378] = "HOA",
	[381] = "SOA",
	[382] = "TOP",
	[377] = "DOS",
	[380] = "SD",
	[391] = "STREET",
	[392] = "GAMBIT",
	[245] = "FH",
	[249] = "KR",
	[250] = "TOS",
	[251] = "UR",
	[369] = "WORK",
	[370] = "WORK",
	[248] = "WM",
	[244] = "AD",
	[353] = "SIEG",
	[247] = "ML",
	[199] = "BRH",
	[210] = "COS",
	[198] = "DHT",
	[200] = "HOV",
	[206] = "NL",
	[227] = "KARA",
	[234] = "KARA",
	[164] = "AUCH",
	[163] = "BSM",
	[239] = "SEAT",
	[168] = "EB",
	[166] = "GD",
	[169] = "ID",
	[165] = "SBG",
	[161] = "SR",
	[167] = "UBRS",
	[57] = "GSS",
	[60] = "MP",
	[76] = "SCHO",
	[77] = "SH",
	[78] = "SM",
	[59] = "SN",
	[58] = "SPM",
	[56] = "SB",
	[2] = "TJS",
	[507] = "GB",
	[456] = "TOTT",
	[438] = "VP",
	[556] = "POS",
	[557] = "WS",
	[558] = "MT",
	[559] = "NPX",
	[560] = "MC",
}

addon.Tooltip.variables.challengeMapID = addon.functions and addon.functions.BuildChallengeMapLabelTable and addon.functions.BuildChallengeMapLabelTable(challengeMapIDDefaults) or challengeMapIDDefaults
