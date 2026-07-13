local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Mouse = addon.Mouse or {}
addon.Mouse.functions = addon.Mouse.functions or {}
addon.Mouse.variables = addon.Mouse.variables or {}
addon.LMouse = addon.LMouse or {} -- Locales for mouse

local function normalizeNumericDropdownValue(key, labels, fallback)
	if not addon.db then return end
	local value = addon.db[key]
	if type(value) == "number" and labels[value] ~= nil then return end
	if type(value) == "string" then
		local numeric = tonumber(value)
		if numeric and labels[numeric] ~= nil then
			addon.db[key] = numeric
			return
		end
		local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
		for index, label in pairs(labels) do
			if trimmed == tostring(label) then
				addon.db[key] = index
				return
			end
		end
	end
	addon.db[key] = fallback
end

function addon.Mouse.functions.InitDB()
	if not addon.db or not addon.functions or not addon.functions.InitDBValue then return end
	local init = addon.functions.InitDBValue
	init("mouseRingEnabled", false)
	init("mouseTrailEnabled", false)
	init("mouseTrailDensity", 1)
	normalizeNumericDropdownValue("mouseTrailDensity", {
		[1] = VIDEO_OPTIONS_LOW or "Low",
		[2] = VIDEO_OPTIONS_MEDIUM or "Medium",
		[3] = VIDEO_OPTIONS_HIGH or "High",
		[4] = VIDEO_OPTIONS_ULTRA or "Ultra",
		[5] = VIDEO_OPTIONS_ULTRA_HIGH or "Ultra High",
	}, 1)
	init("mouseRingSize", 70)
	init("mouseRingHideDot", false)
	-- New options
	init("mouseRingOnlyInCombat", false)
	init("mouseRingOnlyOnRightClick", false)
	init("mouseTrailOnlyInCombat", false)
	init("mouseRingUseClassColor", false)
	init("mouseRingCombatOverride", false)
	init("mouseRingCombatOverrideSize", 70)
	init("mouseRingCombatOverrideColor", { r = 1, g = 0.2, b = 0.2, a = 1 })
	init("mouseRingCombatOverlay", false)
	init("mouseRingCombatOverlaySize", 90)
	init("mouseRingCombatOverlayColor", { r = 1, g = 0.2, b = 0.2, a = 0.6 })
	init("mouseRingCastProgress", false)
	init("mouseRingCastProgressShowOutsideCombat", false)
	init("mouseRingCastProgressColor", { r = 0.9, g = 0.7, b = 0.2, a = 1 })
	init("mouseRingGCDProgress", false)
	init("mouseRingGCDProgressColor", { r = 1, g = 0.82, b = 0.2, a = 1 })
	init("mouseRingGCDProgressMode", "REMAINING")
	init("mouseRingProgressStyle", "DOT")
	init("mouseRingProgressShowEdge", true)
	init("mouseRingProgressHideDuringSwipe", 35)
	init("mouseCrosshairEnabled", false)
	init("mouseCrosshairHideInLegacyRaidInstances", false)
	init("mouseCrosshairThickness", 4)
	init("mouseCrosshairLength", 24)
	init("mouseCrosshairGap", 0)
	init("mouseCrosshairBorderSize", 4)
	init("mouseCrosshairMeleeRange", false)
	init("mouseCrosshairRangeSpells", {})
	init("mouseCrosshairOutOfRangeColor", { r = 1, g = 0.2, b = 0.2, a = 1 })
	init("mouseCrosshairUseClassColor", true)
	init("mouseCrosshairColor", { r = 1, g = 1, b = 1, a = 1 })
	init("mouseCrosshairAlpha", 1)
	init("mouseCrosshairShowWhen", {})
	init("mouseTrailUseClassColor", false)
end
