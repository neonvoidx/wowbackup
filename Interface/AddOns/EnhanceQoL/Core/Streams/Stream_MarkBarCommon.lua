-- luacheck: globals EnhanceQoL InCombatLockdown UIErrorsFrame ERR_NOT_IN_COMBAT
local _, addon = ...

if addon.MarkBarOptions then return end

local MARKBAR_RING_SIZE_OFFSET = 8
local MARKBAR_ICON_SIZE_OFFSET = -4

local function ensureDB()
	addon.db = addon.db or {}
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.markbar = addon.db.datapanel.markbar or {}
	local db = addon.db.datapanel.markbar
	if db.showTargets == nil then db.showTargets = true end
	if db.showWorld == nil then db.showWorld = true end
	if db.showUtility == nil then db.showUtility = true end
	if db.iconSize == nil then db.iconSize = 14 end
	if db.iconSize < 10 then db.iconSize = 10 end
	if db.iconSize > 18 then db.iconSize = 18 end
	return db
end

local function getIconSizes()
	local db = ensureDB()
	local base = db.iconSize or 16
	return base + MARKBAR_RING_SIZE_OFFSET, base + MARKBAR_ICON_SIZE_OFFSET
end

local function requestUpdates()
	if not addon.DataHub or not addon.DataHub.RequestUpdate then return end
	addon.DataHub:RequestUpdate("markbar_target")
	addon.DataHub:RequestUpdate("markbar_world")
	addon.DataHub:RequestUpdate("markbar_util")
end

local function showOptions(focusControlID)
	if InCombatLockdown and InCombatLockdown() then
		if UIErrorsFrame and ERR_NOT_IN_COMBAT then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT) end
		return
	end
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", focusControlID or "DataPanel_markbar_iconSize")
	end
end

addon.MarkBarOptions = {
	Show = showOptions,
	RequestUpdates = requestUpdates,
	EnsureDB = ensureDB,
	GetIconSizes = getIconSizes,
}
