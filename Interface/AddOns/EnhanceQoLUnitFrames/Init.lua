local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

if addon.Aura and addon.Aura.functions then
	if addon.Aura.functions.InitUnitFrames then addon.Aura.functions.InitUnitFrames() end
end

local defaultAuraContainers = addon.DefaultAuraContainers and addon.DefaultAuraContainers.functions
if defaultAuraContainers and defaultAuraContainers.RefreshDefaultAuraIconSkin then defaultAuraContainers.RefreshDefaultAuraIconSkin() end

local castbar = addon.Aura and (addon.Aura.Castbar or addon.Aura.UFStandaloneCastbar)
if castbar and castbar.Refresh then castbar.Refresh() end
