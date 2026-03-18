local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL_DrinkMacro")

local UnitAffectingCombat = UnitAffectingCombat
local InCombatLockdown = InCombatLockdown
local GetMacroInfo = GetMacroInfo
local EditMacro = EditMacro

local buffFoodMacroName = "EnhanceQoLBuffFoodMacro"

local function getCurrentSpecID()
	if addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.getCurrentSpecID then return addon.BuffFoods.functions.getCurrentSpecID() end
	return addon.variables and addon.variables.unitSpecId or nil
end

local function createMacroIfMissing()
	if not addon.db.buffFoodMacroEnabled then return false end
	if GetMacroInfo(buffFoodMacroName) ~= nil then return true end
	if InCombatLockdown and InCombatLockdown() then return false end
	return addon.functions.EnsureGlobalMacro(
		buffFoodMacroName,
		"INV_Misc_QuestionMark",
		"#showtooltip",
		"buffFoodMacroLimitReached",
		L["buffFoodMacroLimitReached"] or "Buff Food Macro: Macro limit reached. Please free a slot."
	)
end

local function buildMacroString(itemID)
	if not itemID then return "#showtooltip" end
	return string.format("#showtooltip item:%d\n/use item:%d", itemID, itemID)
end

local function getBestCandidate(specID)
	if addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.updateAllowedBuffFoods then
		local list = addon.BuffFoods.functions.updateAllowedBuffFoods(specID)
		if type(list) == "table" then return list[1] end
	end

	local list = addon.BuffFoods and addon.BuffFoods.filteredBuffFoods
	if type(list) == "table" then return list[1] end
	return nil
end

local lastMacroToken

function addon.BuffFoods.functions.updateBuffFoodMacro(ignoreCombat)
	if not addon.db.buffFoodMacroEnabled then return end
	if UnitAffectingCombat("player") and ignoreCombat == false then return end

	if not createMacroIfMissing() then return end

	local specID = getCurrentSpecID()
	local best = getBestCandidate(specID)
	local itemID = best and best.id or nil
	local macroToken = itemID and ("item:" .. tostring(itemID)) or "none"
	local macroExists = GetMacroInfo(buffFoodMacroName) ~= nil

	if macroToken ~= lastMacroToken or not macroExists then
		if InCombatLockdown and InCombatLockdown() then return end
		if not GetMacroInfo(buffFoodMacroName) and not createMacroIfMissing() then return end
		if GetMacroInfo(buffFoodMacroName) then
			local macroBody = buildMacroString(itemID)
			EditMacro(buffFoodMacroName, buffFoodMacroName, nil, macroBody)
			lastMacroToken = macroToken
		end
	end
end

function addon.BuffFoods.functions.InitBuffFoodMacro()
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end

	local init = addon.functions.InitDBValue
	init("buffFoodMacroEnabled", false)
	init("buffFoodPreferHearty", true)
	init("buffFoodPreferredBySpec", {})
	init("buffFoodPreferredByRole", {})

	if type(addon.db.buffFoodPreferredBySpec) ~= "table" then addon.db.buffFoodPreferredBySpec = {} end
	if type(addon.db.buffFoodPreferredByRole) ~= "table" then addon.db.buffFoodPreferredByRole = {} end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

local function syncEventRegistration()
	if not addon.db then return end

	if addon.db.buffFoodMacroEnabled then
		frame:RegisterEvent("BAG_UPDATE_DELAYED")
		frame:RegisterEvent("PLAYER_LEVEL_UP")
		frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
		frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	else
		frame:UnregisterEvent("BAG_UPDATE_DELAYED")
		frame:UnregisterEvent("PLAYER_LEVEL_UP")
		frame:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
		frame:UnregisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	end
end

addon.BuffFoods.functions.syncEventRegistration = syncEventRegistration

local pendingBagUpdate = false

frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "PLAYER_LOGIN" then
		syncEventRegistration()
		if addon.db and addon.db.buffFoodMacroEnabled and addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.updateBuffFoodMacro then
			addon.BuffFoods.functions.updateBuffFoodMacro(false)
		end
		return
	end

	if not addon.db or addon.db.buffFoodMacroEnabled ~= true then return end

	if event == "PLAYER_REGEN_ENABLED" then
		if addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.updateBuffFoodMacro then addon.BuffFoods.functions.updateBuffFoodMacro(true) end
	elseif event == "BAG_UPDATE_DELAYED" then
		if pendingBagUpdate then return end
		pendingBagUpdate = true
		C_Timer.After(0.05, function()
			pendingBagUpdate = false
			if addon.db and addon.db.buffFoodMacroEnabled and addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.updateBuffFoodMacro then
				addon.BuffFoods.functions.updateBuffFoodMacro(false)
			end
		end)
	elseif event == "PLAYER_LEVEL_UP" then
		if not UnitAffectingCombat("player") and addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.updateBuffFoodMacro then
			addon.BuffFoods.functions.updateBuffFoodMacro(false)
		end
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		if arg1 and arg1 ~= "player" then return end
		if addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.updateBuffFoodMacro then addon.BuffFoods.functions.updateBuffFoodMacro(false) end
	elseif event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
		if addon.BuffFoods and addon.BuffFoods.functions and addon.BuffFoods.functions.updateBuffFoodMacro then addon.BuffFoods.functions.updateBuffFoodMacro(false) end
	end
end)
