local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

if addon.Aura and addon.Aura.functions then
	if addon.Aura.functions.InitUnitFrames then addon.Aura.functions.InitUnitFrames() end
	if addon.Aura.functions.InitStandalonePrivateAuras then addon.Aura.functions.InitStandalonePrivateAuras() end
end

local castbar = addon.Aura and (addon.Aura.Castbar or addon.Aura.UFStandaloneCastbar)
if castbar and castbar.Refresh then castbar.Refresh() end
