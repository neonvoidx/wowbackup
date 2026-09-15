local addonName, addon = ...

local function buildDefaultAuraContainerSettings()
	if addon.DefaultAuraContainers and addon.DefaultAuraContainers.functions and addon.DefaultAuraContainers.functions.InitSettings then
		addon.DefaultAuraContainers.functions.InitSettings()
	end
end

if addon.Mover and addon.Mover.variables and addon.Mover.variables.settingsBuilt then
	buildDefaultAuraContainerSettings()
elseif addon.Mover and addon.Mover.functions and addon.Mover.functions.InitSettings then
	hooksecurefunc(addon.Mover.functions, "InitSettings", buildDefaultAuraContainerSettings)
else
	buildDefaultAuraContainerSettings()
end
