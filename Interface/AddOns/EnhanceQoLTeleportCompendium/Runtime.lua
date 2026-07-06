local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or {}
addon.MythicPlus.functions = addon.MythicPlus.functions or {}
addon.MythicPlus.variables = addon.MythicPlus.variables or {}

function addon.MythicPlus.functions.InitTeleportCompendium()
	if addon.MythicPlus.variables.teleportCompendiumInitialized then return end
	if not addon.db then return end
	addon.MythicPlus.variables.teleportCompendiumInitialized = true
	if addon.MythicPlus.functions.InitTeleportCompendiumDB then addon.MythicPlus.functions.InitTeleportCompendiumDB() end
	if addon.MythicPlus.functions.InitDungeonPortal then addon.MythicPlus.functions.InitDungeonPortal() end
	if addon.MythicPlus.functions.InitWorldMapTeleportPanel then addon.MythicPlus.functions.InitWorldMapTeleportPanel() end
	if addon.MythicPlus.functions.InitTeleportCompendiumSettings then addon.MythicPlus.functions.InitTeleportCompendiumSettings() end
end
