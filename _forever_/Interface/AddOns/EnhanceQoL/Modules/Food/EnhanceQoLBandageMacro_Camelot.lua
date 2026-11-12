local addon = _G.EnhanceQoL or select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local C = addon.ForeverConsumables
local M = { name = "EnhanceQoLBandageMacro" }

addon.Bandages = addon.Bandages or {}
addon.Bandages.functions = addon.Bandages.functions or {}

local function locked() return InCombatLockdown and InCombatLockdown() end

function addon.Bandages.functions.updateBandageMacro()
	if not addon.db or not addon.db.bandageMacroEnabled or locked() then return end
	local entry = C.GetBestBandage()
	local body = "#showtooltip"
	if entry then body = string.format("#showtooltip item:%d\n/use [nochanneling] item:%d", entry.id, entry.id) end
	if not addon.functions.EnsureGlobalMacro(M.name, "INV_Misc_QuestionMark", body, "bandageMacroLimitReached", L["bandageMacroLimitReached"]) then return end
	local _, _, currentBody = GetMacroInfo(M.name)
	if currentBody ~= body then
		if locked() then return end
		EditMacro(M.name, M.name, nil, body)
	end
end

function addon.Bandages.functions.InitBandageMacro()
	if not addon.db then return end
	addon.functions.InitDBValue("bandageMacroEnabled", false)
end

M.frame = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED", "ZONE_CHANGED_NEW_AREA", "ITEM_DATA_LOAD_RESULT" }) do
	M.frame:RegisterEvent(event)
end
M.frame:SetScript("OnEvent", function(_, event, itemID)
	if not addon.db or not addon.db.bandageMacroEnabled then return end
	if event == "ITEM_DATA_LOAD_RESULT" and not C.requestedItems[itemID] then return end
	if locked() or M.pending then return end
	M.pending = true
	C_Timer.After(0.05, function()
		M.pending = nil
		addon.Bandages.functions.updateBandageMacro()
	end)
end)
