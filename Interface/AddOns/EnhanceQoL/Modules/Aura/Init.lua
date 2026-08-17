local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.functions = addon.Aura.functions or {}
addon.Aura.variables = addon.Aura.variables or {}

function addon.Aura.functions.InitDB()
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end
	local init = addon.functions.InitDBValue


	init("focusInterruptTracker", {
		version = 1,
		enabled = false,
		displayMode = "TEXT",
		text = "INTERRUPT",
		textFont = addon.functions and addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__",
		textSize = 24,
		textOutline = "THICKOUTLINE",
		textColor = { 1, 0.15, 0.15, 1 },
		iconSize = 28,
		customIcon = nil,
		glow = {
			enabled = false,
			style = "MARCHING_ANTS",
			color = { 1, 0.15, 0.15, 1 },
			inset = 0,
			pixelBorder = false,
			pixelCount = 8,
			pixelSpeed = 0.25,
			thickness = 2,
		},
		background = {
			enabled = false,
			color = { 0, 0, 0, 0.35 },
		},
		sound = {
			enabled = false,
			file = "",
		},
		border = {
			enabled = false,
			texture = "DEFAULT",
			size = 1,
			offset = 0,
			color = { 0, 0, 0, 0.9 },
		},
		anchor = {
			point = "TOP",
			relativePoint = "BOTTOM",
			relativeFrame = "AUTO",
			x = 0,
			y = -10,
		},
		strata = "HIGH",
	})
end
