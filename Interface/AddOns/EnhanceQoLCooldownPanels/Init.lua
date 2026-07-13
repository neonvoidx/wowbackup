local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local function initCooldownPanelsDB()
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end
	local init = addon.functions.InitDBValue

	init("cooldownPanels", {
		version = 1,
		panels = {},
		order = {},
		selectedPanel = nil,
		defaults = {
			layout = {
				iconSize = 36,
				spacing = 2,
				direction = "RIGHT",
				wrapCount = 0,
				wrapDirection = "DOWN",
				strata = "MEDIUM",
			},
			entry = {
				alwaysShow = true,
				showCooldown = true,
				showCooldownText = true,
				showCharges = false,
				showStacks = false,
				glowReady = false,
				glowDuration = 0,
			},
		},
	})
	init("cooldownPanelsEditorPoint", "CENTER")
	init("cooldownPanelsEditorX", 0)
	init("cooldownPanelsEditorY", 0)
	init("cooldownPanelsEditorView", "modern")
	addon.db["_cooldownPanelsDebugLog"] = nil
	addon.db["debugCooldownPanelsSession"] = nil

	if addon.Aura and addon.Aura.CooldownPanels and addon.Aura.CooldownPanels.NormalizeAll then addon.Aura.CooldownPanels:NormalizeAll() end
end

initCooldownPanelsDB()

if addon.Aura and addon.Aura.functions and addon.Aura.functions.InitCooldownPanels then addon.Aura.functions.InitCooldownPanels() end
