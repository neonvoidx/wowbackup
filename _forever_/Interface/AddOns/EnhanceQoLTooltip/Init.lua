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
	init("TooltipScale", 1)
	init("TooltipHideOverrideEnabled", false)
	init("TooltipHideOverrideModifier", "CTRL")
	init("TooltipIDRequireModifier", false)
	init("TooltipIDModifier", "ALT")

	init("TooltipUnitHideType", 1)
	init("TooltipUnitHideInCombat", false)
	init("TooltipUnitHideInDungeon", false)
	init("TooltipUnitHideHealthBar", false)
	if not addon.variables.isForever then init("TooltipShowMythicScore", false) end
	if not addon.variables.isForever then init("TooltipMythicScoreRequireModifier", false) end
	init("TooltipMythicScoreModifier", "SHIFT")
	-- Mythic+ tooltip details selection (multiselect)
	-- Keys: score (overall score), best (best run), dungeons (all season dungeons)
	if not addon.variables.isForever then init("TooltipMythicScoreParts", { score = true, best = true, dungeons = true }) end
	init("TooltipShowClassColor", false)
	init("TooltipShowNPCID", false)
	init("TooltipShowNPCWowheadLink", false)
	-- Unit inspect extras
	init("TooltipUnitShowSpec", false)
	init("TooltipUnitShowItemLevel", false)
	if addon.variables.isForever and not addon.variables.isTBC then init("TooltipShowPVPRank", false) end
	-- Gate spec/ilvl lines behind a modifier (uses same modifier as Mythic+ when enabled)
	init("TooltipUnitInspectRequireModifier", false)
	init("TooltipUnitHideRightClickInstruction", false)
	init("TooltipUnitShowTargetOfTarget", false)
	init("TooltipUnitShowMount", false)
	init("TooltipShowRealmInfo", false)
	if addon.db.TooltipRealmInfoFields == nil
		and (type(addon.db.TooltipRealmShowLanguage) == "boolean" or type(addon.db.TooltipRealmShowType) == "boolean"
			or type(addon.db.TooltipRealmShowTimezone) == "boolean" or type(addon.db.TooltipRealmShowConnected) == "boolean") then
		addon.db.TooltipRealmInfoFields = {
			language = addon.db.TooltipRealmShowLanguage ~= false,
			type = addon.db.TooltipRealmShowType ~= false,
			timezone = addon.db.TooltipRealmShowTimezone == true,
			connected = addon.db.TooltipRealmShowConnected ~= false,
		}
	end
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
	if not addon.variables.isForever or addon.variables.isTBC then init("TooltipHousingAutoPreview", false) end
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

-- Tooltip labels are separate from the shared labels used by Mythic+ frames.
local challengeMapIDDefaults = {
	[584] = L["tooltipDungeonShortName584"],
	[585] = L["tooltipDungeonShortName585"],
	[586] = L["tooltipDungeonShortName586"],
	[587] = L["tooltipDungeonShortName587"],
	[588] = L["tooltipDungeonShortName588"],
	[542] = L["tooltipDungeonShortName542"],
	[501] = L["tooltipDungeonShortName501"],
	[502] = L["tooltipDungeonShortName502"],
	[505] = L["tooltipDungeonShortName505"],
	[503] = L["tooltipDungeonShortName503"],
	[525] = L["tooltipDungeonShortName525"],
	[506] = L["tooltipDungeonShortName506"],
	[499] = L["tooltipDungeonShortName499"],
	[504] = L["tooltipDungeonShortName504"],
	[500] = L["tooltipDungeonShortName500"],
	[463] = L["tooltipDungeonShortName463"],
	[464] = L["tooltipDungeonShortName464"],
	[399] = L["tooltipDungeonShortName399"],
	[400] = L["tooltipDungeonShortName400"],
	[405] = L["tooltipDungeonShortName405"],
	[402] = L["tooltipDungeonShortName402"],
	[404] = L["tooltipDungeonShortName404"],
	[401] = L["tooltipDungeonShortName401"],
	[406] = L["tooltipDungeonShortName406"],
	[403] = L["tooltipDungeonShortName403"],
	[376] = L["tooltipDungeonShortName376"],
	[379] = L["tooltipDungeonShortName379"],
	[375] = L["tooltipDungeonShortName375"],
	[378] = L["tooltipDungeonShortName378"],
	[381] = L["tooltipDungeonShortName381"],
	[382] = L["tooltipDungeonShortName382"],
	[377] = L["tooltipDungeonShortName377"],
	[380] = L["tooltipDungeonShortName380"],
	[391] = L["tooltipDungeonShortName391"],
	[392] = L["tooltipDungeonShortName392"],
	[245] = L["tooltipDungeonShortName245"],
	[249] = L["tooltipDungeonShortName249"],
	[250] = L["tooltipDungeonShortName250"],
	[251] = L["tooltipDungeonShortName251"],
	[369] = L["tooltipDungeonShortName369"],
	[370] = L["tooltipDungeonShortName370"],
	[248] = L["tooltipDungeonShortName248"],
	[244] = L["tooltipDungeonShortName244"],
	[353] = L["tooltipDungeonShortName353"],
	[247] = L["tooltipDungeonShortName247"],
	[199] = L["tooltipDungeonShortName199"],
	[210] = L["tooltipDungeonShortName210"],
	[198] = L["tooltipDungeonShortName198"],
	[200] = L["tooltipDungeonShortName200"],
	[206] = L["tooltipDungeonShortName206"],
	[227] = L["tooltipDungeonShortName227"],
	[234] = L["tooltipDungeonShortName234"],
	[164] = L["tooltipDungeonShortName164"],
	[163] = L["tooltipDungeonShortName163"],
	[239] = L["tooltipDungeonShortName239"],
	[168] = L["tooltipDungeonShortName168"],
	[166] = L["tooltipDungeonShortName166"],
	[169] = L["tooltipDungeonShortName169"],
	[165] = L["tooltipDungeonShortName165"],
	[161] = L["tooltipDungeonShortName161"],
	[167] = L["tooltipDungeonShortName167"],
	[57] = L["tooltipDungeonShortName57"],
	[60] = L["tooltipDungeonShortName60"],
	[76] = L["tooltipDungeonShortName76"],
	[77] = L["tooltipDungeonShortName77"],
	[78] = L["tooltipDungeonShortName78"],
	[59] = L["tooltipDungeonShortName59"],
	[58] = L["tooltipDungeonShortName58"],
	[56] = L["tooltipDungeonShortName56"],
	[2] = L["tooltipDungeonShortName2"],
	[507] = L["tooltipDungeonShortName507"],
	[456] = L["tooltipDungeonShortName456"],
	[438] = L["tooltipDungeonShortName438"],
	[556] = L["tooltipDungeonShortName556"],
	[557] = L["tooltipDungeonShortName557"],
	[558] = L["tooltipDungeonShortName558"],
	[559] = L["tooltipDungeonShortName559"],
	[560] = L["tooltipDungeonShortName560"],
}

addon.Tooltip.variables.challengeMapID = challengeMapIDDefaults
