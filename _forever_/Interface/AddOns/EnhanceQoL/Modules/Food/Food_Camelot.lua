local addon = _G.EnhanceQoL or select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local C = addon.ForeverConsumables
local M = { name = "EnhanceQoLDrinkMacro" }

local function locked() return InCombatLockdown and InCombatLockdown() end

local function hasMana()
	local mana = UnitPowerMax("player", 0)
	if issecretvalue and issecretvalue(mana) then return false end
	return type(mana) == "number" and mana > 0
end

local function bestDrink()
	local best, remaining
	for _, wrapped in ipairs(addon.Drinks.filteredDrinks) do
		local entry = C.byID[wrapped.id]
		if C.GetCount(entry) > 0 then
			C.RequestOwnedItemData(entry)
			local cooldown = C.GetCooldown(entry)
			if cooldown < math.huge and C.IsBetter(entry, best, "mana", addon.db.preferMageFood, cooldown, remaining) then
				best, remaining = entry, cooldown
			end
		end
	end
	return best
end

function addon.functions.updateAvailableDrinks()
	if not addon.db or not addon.db.drinkMacroEnabled or locked() then return end
	if not GetMacroInfo(M.name) then M.lastBody = nil end
	if not addon.functions.EnsureGlobalMacro(M.name, "INV_Misc_QuestionMark", "#showtooltip", "drinkMacroLimitReached", L["drinkMacroLimitReached"]) then return end
	addon.functions.updateAllowedDrinks()
	local food = addon.db.drinkMacroIncludeFood and C.GetBest("food", "health", addon.db.preferMageFood) or nil
	local drink = hasMana() and bestDrink() or nil
	-- Combined recovery is one action: another food/drink can block its shared cooldown.
	if drink and drink.category == "food_and_drink" then
		food = drink
	elseif food and food.category == "food_and_drink" then
		drink = food
	end
	local mana = hasMana() and addon.db.useManaPotionInCombat and C.GetBest("mana", "mana", false) or nil
	local parts = { "#showtooltip" }
	if mana then parts[#parts + 1] = "/use [combat] item:" .. mana.id end
	if drink then parts[#parts + 1] = "/use [nocombat] item:" .. drink.id end
	if food and (not drink or food.id ~= drink.id) then parts[#parts + 1] = "/use [nocombat] item:" .. food.id end
	local body = table.concat(parts, "\n")
	local _, _, currentBody = GetMacroInfo(M.name)
	if body ~= M.lastBody or currentBody ~= body then
		if locked() then return end
		EditMacro(M.name, M.name, nil, body)
		M.lastBody = body
	end
end

function addon.Drinks.functions.InitDrinkMacro()
	if not addon.db then return end
	local init = addon.functions.InitDBValue
	init("minManaFoodValue", 0)
	init("preferMageFood", true)
	init("drinkMacroEnabled", false)
	init("drinkMacroIncludeFood", false)
	init("useManaPotionInCombat", false)
	addon.functions.updateAllowedDrinks()
end

M.frame = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "UNIT_MAXPOWER", "UNIT_MAXHEALTH", "SPELLS_CHANGED", "ITEM_DATA_LOAD_RESULT" }) do
	M.frame:RegisterEvent(event)
end
M.frame:SetScript("OnEvent", function(_, event, unit)
	if not addon.db or not addon.db.drinkMacroEnabled then return end
	if (event == "UNIT_MAXPOWER" or event == "UNIT_MAXHEALTH") and unit ~= "player" then return end
	if event == "ITEM_DATA_LOAD_RESULT" and not C.requestedItems[unit] then return end
	if locked() or M.pending then return end
	M.pending = true
	C_Timer.After(0.05, function()
		M.pending = nil
		addon.functions.updateAvailableDrinks()
	end)
end)
