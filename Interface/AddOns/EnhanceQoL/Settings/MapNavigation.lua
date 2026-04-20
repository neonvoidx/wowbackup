local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local C_GameRules = _G.C_GameRules
local getCVarOptionState = addon.functions.GetCVarOptionState or function() return false end
local setCVarOptionState = addon.functions.SetCVarOptionState or function() end

local cMapNav = addon.SettingsLayout.rootUI
addon.SettingsLayout.mapNavigationCategory = cMapNav

local refreshWorldMapCoordinates

local mapExpandable = addon.functions.SettingsCreateExpandableSection(cMapNav, {
	name = L["MapNavigation"],
	newTagID = "MapNavigation",
	expanded = false,
	colorizeTitle = false,
})

local function isSettingEnabled(varName)
	return addon.SettingsLayout.elements[varName] and addon.SettingsLayout.elements[varName].setting and addon.SettingsLayout.elements[varName].setting:GetValue() == true
end

local function isSquareMinimapEnabledSetting() return isSettingEnabled("enableSquareMinimap") end
local function isSquareMinimapBorderEnabledSetting() return isSquareMinimapEnabledSetting() and isSettingEnabled("enableSquareMinimapBorder") end
local function isSquareMinimapBackgroundEnabledSetting() return isSquareMinimapEnabledSetting() and isSettingEnabled("enableSquareMinimapBackground") end

local function isSquareMinimapStatsEnabledSetting() return isSquareMinimapEnabledSetting() and isSettingEnabled("enableSquareMinimapStats") end

local function isSquareMinimapStatElementEnabled(settingKey)
	return function() return isSquareMinimapStatsEnabledSetting() and isSettingEnabled(settingKey) end
end

local function applySquareMinimapStatsNow(force)
	if addon.functions and addon.functions.applySquareMinimapStats then addon.functions.applySquareMinimapStats(force) end
end

local function getSettingSelectedValue(primary, secondary)
	if secondary ~= nil then return secondary end
	return primary
end

local squareMinimapStatsFontOrder = {}
local squareMinimapBorderTextureOptions = {}
local squareMinimapBorderTextureOrder = {}
local squareMinimapBorderTextureCacheVersion = -1
local squareMinimapStatsOutlineOptions, squareMinimapStatsOutlineOrder =
	addon.functions.GetFontStyleOptions and addon.functions.GetFontStyleOptions(true) or {
		NONE = NONE,
		OUTLINE = L["Outline"] or "Outline",
	}, { "NONE", "OUTLINE" }
local squareMinimapStatsAnchorOrder = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local squareMinimapStatsAnchorOptions = {
	TOPLEFT = L["Top Left"] or "Top Left",
	TOP = L["Top"] or "Top",
	TOPRIGHT = L["Top Right"] or "Top Right",
	LEFT = L["Left"] or "Left",
	CENTER = L["Center"] or "Center",
	RIGHT = L["Right"] or "Right",
	BOTTOMLEFT = L["Bottom Left"] or "Bottom Left",
	BOTTOM = L["Bottom"] or "Bottom",
	BOTTOMRIGHT = L["Bottom Right"] or "Bottom Right",
}
local instanceDifficultyAnchorOptions = {
	TOPLEFT = squareMinimapStatsAnchorOptions.TOPLEFT,
	TOP = squareMinimapStatsAnchorOptions.TOP,
	TOPRIGHT = squareMinimapStatsAnchorOptions.TOPRIGHT,
	LEFT = squareMinimapStatsAnchorOptions.LEFT,
	CENTER = _G.DEFAULT or "Default",
	RIGHT = squareMinimapStatsAnchorOptions.RIGHT,
	BOTTOMLEFT = squareMinimapStatsAnchorOptions.BOTTOMLEFT,
	BOTTOM = squareMinimapStatsAnchorOptions.BOTTOM,
	BOTTOMRIGHT = squareMinimapStatsAnchorOptions.BOTTOMRIGHT,
}
local squareMinimapStatsTimeLeftClickActionOrder = { "calendar", "clock" }
local squareMinimapStatsTimeLeftClickActionOptions = {
	calendar = L["Time left-click opens calendar"] or "Open calendar",
	clock = L["Time left-click opens stopwatch"] or "Open stopwatch",
}
local wipeTable = _G.wipe or table.wipe

local function getCachedFontMedia()
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("font")
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("font")
	if type(names) == "table" and type(hash) == "table" then return names, hash end
	return {}, {}
end

local function getGlobalFontConfigKey()
	if addon.functions and addon.functions.GetGlobalFontConfigKey then return addon.functions.GetGlobalFontConfigKey() end
	return "__EQOL_GLOBAL_FONT__"
end

local function getGlobalFontConfigLabel()
	if addon.functions and addon.functions.GetGlobalFontConfigLabel then return addon.functions.GetGlobalFontConfigLabel() end
	return "Use global font config"
end

local function getGlobalFontStyleConfigKey()
	if addon.functions and addon.functions.GetGlobalFontStyleConfigKey then return addon.functions.GetGlobalFontStyleConfigKey() end
	return "__EQOL_GLOBAL_FONT_STYLE__"
end

local function normalizeSquareMinimapStatsOutlineSelection(primary, secondary)
	local outline = getSettingSelectedValue(primary, secondary)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(outline, getGlobalFontStyleConfigKey(), true)
	end
	if outline == nil or outline == "" then return getGlobalFontStyleConfigKey() end
	if outline == "NONE" then return "NONE" end
	if squareMinimapStatsOutlineOptions[outline] then return outline end
	return getGlobalFontStyleConfigKey()
end

local function normalizeSquareMinimapTimeLeftClickAction(primary, secondary)
	local action = getSettingSelectedValue(primary, secondary)
	if action == "calendar" then return "calendar" end
	return "clock"
end

local function normalizeSquareMinimapAnchorSelection(primary, secondary, fallback)
	local anchor = getSettingSelectedValue(primary, secondary)
	if type(anchor) == "string" and squareMinimapStatsAnchorOptions[anchor] then return anchor end
	if type(fallback) == "string" and squareMinimapStatsAnchorOptions[fallback] then return fallback end
	return "CENTER"
end

local function normalizeSquareMinimapStatsFontSelection(primary, secondary)
	local fallback = getGlobalFontConfigKey()
	local selected = getSettingSelectedValue(primary, secondary)
	if addon.functions and addon.functions.IsGlobalFontConfigValue and addon.functions.IsGlobalFontConfigValue(selected) then return fallback end
	if type(selected) == "string" and selected ~= "" then return selected end
	return fallback
end

local function buildSquareMinimapStatsFontDropdown()
	local defaultFont = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	local globalFontKey = getGlobalFontConfigKey()
	local globalFontLabel = getGlobalFontConfigLabel()
	local map = {
		[defaultFont] = L["actionBarFontDefault"] or "Blizzard font",
		[globalFontKey] = globalFontLabel,
	}
	local names, hash = getCachedFontMedia()
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then map[path] = tostring(name) end
	end
	local list, order = addon.functions.prepareListForDropdown(map)
	wipe(squareMinimapStatsFontOrder)
	if list[globalFontKey] then squareMinimapStatsFontOrder[#squareMinimapStatsFontOrder + 1] = globalFontKey end
	for _, key in ipairs(order or {}) do
		if key ~= globalFontKey then squareMinimapStatsFontOrder[#squareMinimapStatsFontOrder + 1] = key end
	end
	return list
end

local function buildSquareMinimapBorderTextureDropdown()
	local version = (addon.functions and addon.functions.GetLSMMediaVersion and addon.functions.GetLSMMediaVersion("border")) or 0
	if squareMinimapBorderTextureCacheVersion == version then return squareMinimapBorderTextureOptions end
	squareMinimapBorderTextureCacheVersion = version

	local map = {
		DEFAULT = _G.DEFAULT or "Default",
		SOLID = "Solid",
	}
	local mediaOptions = addon.functions and addon.functions.GetLSMMediaOptions and addon.functions.GetLSMMediaOptions("border") or {}
	for i = 1, #mediaOptions do
		local option = mediaOptions[i]
		if option and type(option.value) == "string" and option.value ~= "" then map[option.value] = option.label or option.value end
	end

	local list, order = addon.functions.prepareListForDropdown(map)
	wipeTable(squareMinimapBorderTextureOptions)
	for key, value in pairs(list or {}) do
		squareMinimapBorderTextureOptions[key] = value
	end
	wipeTable(squareMinimapBorderTextureOrder)
	if squareMinimapBorderTextureOptions.DEFAULT then squareMinimapBorderTextureOrder[#squareMinimapBorderTextureOrder + 1] = "DEFAULT" end
	if squareMinimapBorderTextureOptions.SOLID then squareMinimapBorderTextureOrder[#squareMinimapBorderTextureOrder + 1] = "SOLID" end
	for i = 1, #(order or {}) do
		local key = order[i]
		if key ~= "DEFAULT" and key ~= "SOLID" then squareMinimapBorderTextureOrder[#squareMinimapBorderTextureOrder + 1] = key end
	end
	return squareMinimapBorderTextureOptions
end

local function normalizeSquareMinimapBorderTextureSelection(primary, secondary)
	local selected = getSettingSelectedValue(primary, secondary)
	local list = buildSquareMinimapBorderTextureDropdown()
	if type(selected) == "string" and list[selected] then return selected end
	return "DEFAULT"
end

addon.functions.SettingsCreateHeadline(cMapNav, L["MapBasics"] or "Map Basics", { parentSection = mapExpandable })

local data = {
	{
		var = "enableWayCommand",
		text = L["enableWayCommand"],
		desc = L["enableWayCommandDesc"],
		func = function(key)
			addon.db["enableWayCommand"] = key
			if key then
				addon.functions.registerWayCommand()
			else
				addon.variables.requireReload = true
			end
		end,
		default = false,
		parentSection = mapExpandable,
	},
	{
		var = "showWorldMapCoordinates",
		text = L["showWorldMapCoordinates"],
		desc = L["showWorldMapCoordinatesDesc"],
		func = function(value)
			addon.db["showWorldMapCoordinates"] = value
			if value then
				addon.functions.EnableWorldMapCoordinates()
			else
				addon.functions.DisableWorldMapCoordinates()
			end
		end,
		default = false,
		parentSection = mapExpandable,
		children = {
			{
				var = "worldMapCoordinatesUpdateInterval",
				text = L["worldMapCoordinatesUpdateInterval"] or "Coordinates update interval (s)",
				desc = L["worldMapCoordinatesUpdateIntervalDesc"],
				get = function() return addon.db and addon.db.worldMapCoordinatesUpdateInterval or 0.1 end,
				set = function(value)
					addon.db["worldMapCoordinatesUpdateInterval"] = value
					if refreshWorldMapCoordinates then refreshWorldMapCoordinates(true) end
				end,
				min = 0.01,
				max = 1.00,
				step = 0.01,
				default = 0.1,
				sType = "slider",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["showWorldMapCoordinates"]
						and addon.SettingsLayout.elements["showWorldMapCoordinates"].setting
						and addon.SettingsLayout.elements["showWorldMapCoordinates"].setting:GetValue() == true
				end,
				parentSection = mapExpandable,
			},
			{
				var = "worldMapCoordinatesHideCursor",
				text = L["worldMapCoordinatesHideCursor"] or "Hide cursor coordinates off-map",
				desc = L["worldMapCoordinatesHideCursorDesc"],
				func = function(value)
					addon.db["worldMapCoordinatesHideCursor"] = value and true or false
					if refreshWorldMapCoordinates then refreshWorldMapCoordinates() end
				end,
				default = true,
				sType = "checkbox",
				parent = true,
				parentCheck = function()
					return addon.SettingsLayout.elements["showWorldMapCoordinates"]
						and addon.SettingsLayout.elements["showWorldMapCoordinates"].setting
						and addon.SettingsLayout.elements["showWorldMapCoordinates"].setting:GetValue() == true
				end,
				parentSection = mapExpandable,
			},
		},
	},
}

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cMapNav, data)

addon.functions.SettingsCreateHeadline(cMapNav, L["SquareMinimap"] or "Square Minimap", { parentSection = mapExpandable })

data = {
	{
		var = "enableSquareMinimap",
		text = L["SquareMinimap"],
		desc = L["enableSquareMinimapDesc"],
		func = function(key)
			addon.db["enableSquareMinimap"] = key
			applySquareMinimapStatsNow(true)
			addon.variables.requireReload = true
			addon.functions.checkReloadFrame()
		end,
		default = false,
		parentSection = mapExpandable,
		children = {
			{
				var = "enableSquareMinimapLayout",
				text = L["enableSquareMinimapLayout"],
				desc = L["enableSquareMinimapLayoutDesc"],
				func = function(key)
					addon.db["enableSquareMinimapLayout"] = key
					if addon.functions.applySquareMinimapLayout then addon.functions.applySquareMinimapLayout() end
					addon.variables.requireReload = true
					addon.functions.checkReloadFrame()
				end,
				get = function() return addon.db["enableSquareMinimapLayout"] or false end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["enableSquareMinimap"]
						and addon.SettingsLayout.elements["enableSquareMinimap"].setting
						and addon.SettingsLayout.elements["enableSquareMinimap"].setting:GetValue() == true
				end,
				parent = true,
				notify = "enableSquareMinimap",
				parentSection = mapExpandable,
			},
			{
				var = "enableSquareMinimapBackground",
				text = L["enableSquareMinimapBackground"] or "Enable square minimap background panel",
				desc = L["enableSquareMinimapBackgroundDesc"] or "Adds a colored panel behind the square minimap. Increase the offset to create a shadow-like backdrop.",
				func = function(key)
					addon.db["enableSquareMinimapBackground"] = key
					if addon.functions.applySquareMinimapBackground then addon.functions.applySquareMinimapBackground() end
				end,
				default = false,
				sType = "checkbox",
				parentCheck = isSquareMinimapEnabledSetting,
				parent = true,
				notify = "enableSquareMinimap",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapBackgroundOffset",
				text = L["squareMinimapBackgroundOffset"] or "Square minimap background offset",
				parentCheck = isSquareMinimapBackgroundEnabledSetting,
				get = function()
					local value = tonumber(addon.db and addon.db.squareMinimapBackgroundOffset) or 8
					if value < -30 then value = -30 end
					if value > 30 then value = 30 end
					return value
				end,
				set = function(value)
					value = tonumber(value) or 0
					if value < -30 then value = -30 end
					if value > 30 then value = 30 end
					addon.db["squareMinimapBackgroundOffset"] = value
					if addon.functions.applySquareMinimapBackground then addon.functions.applySquareMinimapBackground() end
				end,
				min = -30,
				max = 30,
				step = 1,
				parent = true,
				default = 8,
				sType = "slider",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapBackgroundColor",
				text = L["squareMinimapBackgroundColor"] or "Square minimap background color",
				parentCheck = isSquareMinimapBackgroundEnabledSetting,
				parent = true,
				hasOpacity = true,
				default = false,
				sType = "colorpicker",
				notify = "enableSquareMinimapBackground",
				callback = function()
					if addon.functions.applySquareMinimapBackground then addon.functions.applySquareMinimapBackground() end
				end,
				parentSection = mapExpandable,
			},
			{
				var = "enableSquareMinimapBorder",
				text = L["enableSquareMinimapBorder"],
				desc = L["enableSquareMinimapBorderDesc"],
				func = function(key)
					addon.db["enableSquareMinimapBorder"] = key
					if addon.functions.applySquareMinimapBorder then addon.functions.applySquareMinimapBorder() end
				end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["enableSquareMinimap"]
						and addon.SettingsLayout.elements["enableSquareMinimap"].setting
						and addon.SettingsLayout.elements["enableSquareMinimap"].setting:GetValue() == true
				end,
				parent = true,
				notify = "enableSquareMinimap",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapBorderTexture",
				text = L["squareMinimapBorderTexture"] or "Square minimap border texture",
				listFunc = buildSquareMinimapBorderTextureDropdown,
				order = squareMinimapBorderTextureOrder,
				parentCheck = isSquareMinimapBorderEnabledSetting,
				get = function() return normalizeSquareMinimapBorderTextureSelection(addon.db and addon.db.squareMinimapBorderTexture, nil) end,
				set = function(value, maybeValue)
					addon.db["squareMinimapBorderTexture"] = normalizeSquareMinimapBorderTextureSelection(value, maybeValue)
					if addon.functions.applySquareMinimapBorder then addon.functions.applySquareMinimapBorder() end
				end,
				default = "DEFAULT",
				sType = "scrolldropdown",
				parent = true,
				notify = "enableSquareMinimapBorder",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapBorderSize",
				text = L["squareMinimapBorderSize"],
				parentCheck = isSquareMinimapBorderEnabledSetting,
				get = function()
					local value = tonumber(addon.db and addon.db.squareMinimapBorderSize) or 1
					if value < 1 then value = 1 end
					if value > 60 then value = 60 end
					return value
				end,
				set = function(value)
					value = math.floor((tonumber(value) or 1) + 0.5)
					if value < 1 then value = 1 end
					if value > 60 then value = 60 end
					addon.db["squareMinimapBorderSize"] = value
					if addon.functions.applySquareMinimapBorder then addon.functions.applySquareMinimapBorder() end
				end,
				min = 1,
				max = 60,
				step = 1,
				parent = true,
				default = 1,
				sType = "slider",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapBorderOffset",
				text = L["squareMinimapBorderOffset"] or "Square minimap border offset",
				parentCheck = isSquareMinimapBorderEnabledSetting,
				get = function()
					local value = tonumber(addon.db and addon.db.squareMinimapBorderOffset) or 0
					if value < -30 then value = -30 end
					if value > 30 then value = 30 end
					return value
				end,
				set = function(value)
					value = tonumber(value) or 0
					if value < -30 then value = -30 end
					if value > 30 then value = 30 end
					addon.db["squareMinimapBorderOffset"] = value
					if addon.functions.applySquareMinimapBorder then addon.functions.applySquareMinimapBorder() end
				end,
				min = -30,
				max = 30,
				step = 1,
				parent = true,
				default = 0,
				sType = "slider",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapBorderColor",
				text = L["squareMinimapBorderColor"],
				parentCheck = isSquareMinimapBorderEnabledSetting,
				parent = true,
				hasOpacity = true,
				default = false,
				sType = "colorpicker",
				notify = "enableSquareMinimapBorder",
				callback = function()
					if addon.functions.applySquareMinimapBorder then addon.functions.applySquareMinimapBorder() end
				end,
				parentSection = mapExpandable,
			},
		},
	},
}

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cMapNav, data)

addon.functions.SettingsCreateHeadline(cMapNav, L["SquareMinimapStats"] or "Square Minimap Stats", { parentSection = mapExpandable })

data = {
	{
		var = "enableSquareMinimapStats",
		text = L["enableSquareMinimapStats"] or "Enable minimap stats",
		desc = L["enableSquareMinimapStatsDesc"] or "Show configurable stats around the square minimap.",
		func = function(key)
			addon.db["enableSquareMinimapStats"] = key and true or false
			applySquareMinimapStatsNow(true)
		end,
		default = false,
		parent = true,
		parentCheck = isSquareMinimapEnabledSetting,
		notify = "enableSquareMinimap",
		parentSection = mapExpandable,
		children = {
			{
				var = "squareMinimapStatsFont",
				text = L["squareMinimapStatsFont"] or "Font (all stats)",
				listFunc = buildSquareMinimapStatsFontDropdown,
				order = squareMinimapStatsFontOrder,
				default = getGlobalFontConfigKey(),
				get = function()
					local globalFontKey = getGlobalFontConfigKey()
					local current = addon.db and addon.db.squareMinimapStatsFont or globalFontKey
					local list = buildSquareMinimapStatsFontDropdown()
					if not list[current] then current = globalFontKey end
					return current
				end,
				set = function(value, maybeValue)
					addon.db["squareMinimapStatsFont"] = normalizeSquareMinimapStatsFontSelection(value, maybeValue)
					applySquareMinimapStatsNow(true)
				end,
				sType = "scrolldropdown",
				parent = true,
				parentCheck = isSquareMinimapStatsEnabledSetting,
				notify = "enableSquareMinimapStats",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapStatsOutline",
				text = L["squareMinimapStatsOutline"] or "Outline (all stats)",
				list = squareMinimapStatsOutlineOptions,
				order = squareMinimapStatsOutlineOrder,
				get = function() return normalizeSquareMinimapStatsOutlineSelection(addon.db and addon.db.squareMinimapStatsOutline, nil) end,
				set = function(value, maybeValue)
					addon.db["squareMinimapStatsOutline"] = normalizeSquareMinimapStatsOutlineSelection(value, maybeValue)
					applySquareMinimapStatsNow(true)
				end,
				default = getGlobalFontStyleConfigKey(),
				sType = "dropdown",
				parent = true,
				parentCheck = isSquareMinimapStatsEnabledSetting,
				notify = "enableSquareMinimapStats",
				parentSection = mapExpandable,
			},
			{
				text = "",
				sType = "hint",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapStatsTime",
				text = L["Time"] or "Time",
				func = function(key)
					addon.db["squareMinimapStatsTime"] = key and true or false
					applySquareMinimapStatsNow(true)
				end,
				default = true,
				sType = "checkbox",
				parent = true,
				parentCheck = isSquareMinimapStatsEnabledSetting,
				notify = "enableSquareMinimapStats",
				parentSection = mapExpandable,
				children = {
					{
						var = "squareMinimapStatsTimeDisplayMode",
						text = DISPLAY_MODE,
						list = {
							server = L["Server time"] or "Server time",
							localTime = L["Local time"] or "Local time",
							both = L["Server + Local"] or "Server + Local",
						},
						get = function() return addon.db and addon.db.squareMinimapStatsTimeDisplayMode or "server" end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsTimeDisplayMode"] = getSettingSelectedValue(value, maybeValue)
							applySquareMinimapStatsNow(true)
						end,
						default = "server",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						notify = "squareMinimapStatsTime",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeUse24Hour",
						text = L["squareMinimapStatsTimeUse24Hour"] or "Use 24-hour format",
						func = function(value)
							addon.db["squareMinimapStatsTimeUse24Hour"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = true,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						notify = "squareMinimapStatsTime",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeShowSeconds",
						text = L["Show seconds"] or "Show seconds",
						func = function(value)
							addon.db["squareMinimapStatsTimeShowSeconds"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = false,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						notify = "squareMinimapStatsTime",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeLeftClickAction",
						text = L["Left-click action"] or "Left-click action",
						list = squareMinimapStatsTimeLeftClickActionOptions,
						order = squareMinimapStatsTimeLeftClickActionOrder,
						get = function() return normalizeSquareMinimapTimeLeftClickAction(addon.db and addon.db.squareMinimapStatsTimeLeftClickAction, nil) end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsTimeLeftClickAction"] = normalizeSquareMinimapTimeLeftClickAction(value, maybeValue)
							applySquareMinimapStatsNow(true)
						end,
						default = "calendar",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						notify = "squareMinimapStatsTime",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeAnchor",
						text = L["Anchor"] or "Anchor",
						list = squareMinimapStatsAnchorOptions,
						order = squareMinimapStatsAnchorOrder,
						get = function() return addon.db and addon.db.squareMinimapStatsTimeAnchor or "BOTTOMLEFT" end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsTimeAnchor"] = normalizeSquareMinimapAnchorSelection(value, maybeValue, "BOTTOMLEFT")
							applySquareMinimapStatsNow(true)
						end,
						default = "BOTTOMLEFT",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeOffsetX",
						text = L["Horizontal offset"] or "Horizontal offset",
						get = function() return addon.db and addon.db.squareMinimapStatsTimeOffsetX or 3 end,
						set = function(value)
							addon.db["squareMinimapStatsTimeOffsetX"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = 3,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeOffsetY",
						text = L["Vertical offset"] or "Vertical offset",
						get = function() return addon.db and addon.db.squareMinimapStatsTimeOffsetY or 17 end,
						set = function(value)
							addon.db["squareMinimapStatsTimeOffsetY"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = 17,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeFontSize",
						text = FONT_SIZE,
						get = function() return addon.db and addon.db.squareMinimapStatsTimeFontSize or 18 end,
						set = function(value)
							addon.db["squareMinimapStatsTimeFontSize"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 8,
						max = 32,
						step = 1,
						default = 18,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeUseClassColor",
						text = L["Use class color"] or "Use class color",
						func = function(value)
							addon.db["squareMinimapStatsTimeUseClassColor"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = false,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTime"),
						notify = "squareMinimapStatsTime",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTimeColor",
						text = L["Text color"] or "Text color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = function() return isSquareMinimapStatElementEnabled("squareMinimapStatsTime")() and addon.db and addon.db.squareMinimapStatsTimeUseClassColor ~= true end,
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
				},
			},
			{
				text = "",
				sType = "hint",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapStatsFPS",
				text = L["squareMinimapStatsFPS"] or "FPS",
				func = function(key)
					addon.db["squareMinimapStatsFPS"] = key and true or false
					applySquareMinimapStatsNow(true)
				end,
				default = true,
				sType = "checkbox",
				parent = true,
				parentCheck = isSquareMinimapStatsEnabledSetting,
				notify = "enableSquareMinimapStats",
				parentSection = mapExpandable,
				children = {
					{
						var = "squareMinimapStatsFPSUpdateInterval",
						text = L["squareMinimapStatsUpdateInterval"] or "Update interval (s)",
						get = function() return addon.db and addon.db.squareMinimapStatsFPSUpdateInterval or 0.25 end,
						set = function(value)
							addon.db["squareMinimapStatsFPSUpdateInterval"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 0.1,
						max = 2.0,
						step = 0.05,
						default = 0.25,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSThresholdMedium",
						text = L["squareMinimapStatsFPSThresholdMedium"] or "Medium threshold (FPS)",
						get = function() return addon.db and addon.db.squareMinimapStatsFPSThresholdMedium or 30 end,
						set = function(value)
							local medium = math.floor((tonumber(value) or 30) + 0.5)
							if medium < 1 then medium = 1 end
							addon.db["squareMinimapStatsFPSThresholdMedium"] = medium
							local high = math.floor((tonumber(addon.db["squareMinimapStatsFPSThresholdHigh"]) or 60) + 0.5)
							if high < medium then addon.db["squareMinimapStatsFPSThresholdHigh"] = medium end
							applySquareMinimapStatsNow(true)
						end,
						min = 1,
						max = 240,
						step = 1,
						default = 30,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSThresholdHigh",
						text = L["squareMinimapStatsFPSThresholdHigh"] or "High threshold (FPS)",
						get = function() return addon.db and addon.db.squareMinimapStatsFPSThresholdHigh or 60 end,
						set = function(value)
							local high = math.floor((tonumber(value) or 60) + 0.5)
							if high < 1 then high = 1 end
							addon.db["squareMinimapStatsFPSThresholdHigh"] = high
							local medium = math.floor((tonumber(addon.db["squareMinimapStatsFPSThresholdMedium"]) or 30) + 0.5)
							if medium > high then addon.db["squareMinimapStatsFPSThresholdMedium"] = high end
							applySquareMinimapStatsNow(true)
						end,
						min = 1,
						max = 240,
						step = 1,
						default = 60,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSColorLow",
						text = L["squareMinimapStatsColorLow"] or "Low color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSColorMid",
						text = L["squareMinimapStatsColorMid"] or "Medium color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSColorHigh",
						text = L["High color"] or "High color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSAnchor",
						text = L["Anchor"] or "Anchor",
						list = squareMinimapStatsAnchorOptions,
						order = squareMinimapStatsAnchorOrder,
						get = function() return addon.db and addon.db.squareMinimapStatsFPSAnchor or "BOTTOMLEFT" end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsFPSAnchor"] = normalizeSquareMinimapAnchorSelection(value, maybeValue, "BOTTOMLEFT")
							applySquareMinimapStatsNow(true)
						end,
						default = "BOTTOMLEFT",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSOffsetX",
						text = L["Horizontal offset"] or "Horizontal offset",
						get = function() return addon.db and addon.db.squareMinimapStatsFPSOffsetX or 3 end,
						set = function(value)
							addon.db["squareMinimapStatsFPSOffsetX"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = 3,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSOffsetY",
						text = L["Vertical offset"] or "Vertical offset",
						get = function() return addon.db and addon.db.squareMinimapStatsFPSOffsetY or 3 end,
						set = function(value)
							addon.db["squareMinimapStatsFPSOffsetY"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = 3,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSFontSize",
						text = FONT_SIZE,
						get = function() return addon.db and addon.db.squareMinimapStatsFPSFontSize or 12 end,
						set = function(value)
							addon.db["squareMinimapStatsFPSFontSize"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 8,
						max = 32,
						step = 1,
						default = 12,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSUseClassColor",
						text = L["Use class color"] or "Use class color",
						func = function(value)
							addon.db["squareMinimapStatsFPSUseClassColor"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = false,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsFPS"),
						notify = "squareMinimapStatsFPS",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsFPSColor",
						text = L["Text color"] or "Text color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = function() return isSquareMinimapStatElementEnabled("squareMinimapStatsFPS")() and addon.db and addon.db.squareMinimapStatsFPSUseClassColor ~= true end,
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
				},
			},
			{
				text = "",
				sType = "hint",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapStatsLatency",
				text = L["Latency"] or "Latency",
				func = function(key)
					addon.db["squareMinimapStatsLatency"] = key and true or false
					applySquareMinimapStatsNow(true)
				end,
				default = true,
				sType = "checkbox",
				parent = true,
				parentCheck = isSquareMinimapStatsEnabledSetting,
				notify = "enableSquareMinimapStats",
				parentSection = mapExpandable,
				children = {
					{
						var = "squareMinimapStatsLatencyMode",
						text = L["squareMinimapStatsLatencyMode"] or "Display mode",
						list = {
							max = L["Max(home, world)"] or "Max(home, world)",
							home = L["squareMinimapStatsLatencyModeHome"] or "Home",
							world = L["World"] or "World",
							split = L["Home + World"] or "Home + World",
							split_vertical = L["Home + World (vertical)"] or "Home + World (vertical)",
						},
						get = function() return addon.db and addon.db.squareMinimapStatsLatencyMode or "max" end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsLatencyMode"] = getSettingSelectedValue(value, maybeValue)
							applySquareMinimapStatsNow(true)
						end,
						default = "max",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						notify = "squareMinimapStatsLatency",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyUpdateInterval",
						text = L["squareMinimapStatsUpdateInterval"] or "Update interval (s)",
						get = function() return addon.db and addon.db.squareMinimapStatsLatencyUpdateInterval or 1.0 end,
						set = function(value)
							addon.db["squareMinimapStatsLatencyUpdateInterval"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 0.2,
						max = 5.0,
						step = 0.1,
						default = 1.0,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyThresholdLow",
						text = L["Low threshold (ms)"] or "Low threshold (ms)",
						get = function() return addon.db and addon.db.squareMinimapStatsLatencyThresholdLow or 50 end,
						set = function(value)
							local low = math.floor((tonumber(value) or 50) + 0.5)
							if low < 0 then low = 0 end
							addon.db["squareMinimapStatsLatencyThresholdLow"] = low
							local mid = math.floor((tonumber(addon.db["squareMinimapStatsLatencyThresholdMid"]) or 150) + 0.5)
							if mid < low then addon.db["squareMinimapStatsLatencyThresholdMid"] = low end
							applySquareMinimapStatsNow(true)
						end,
						min = 0,
						max = 1000,
						step = 1,
						default = 50,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyThresholdMid",
						text = L["squareMinimapStatsLatencyThresholdMid"] or "Medium threshold (ms)",
						get = function() return addon.db and addon.db.squareMinimapStatsLatencyThresholdMid or 150 end,
						set = function(value)
							local mid = math.floor((tonumber(value) or 150) + 0.5)
							if mid < 0 then mid = 0 end
							addon.db["squareMinimapStatsLatencyThresholdMid"] = mid
							local low = math.floor((tonumber(addon.db["squareMinimapStatsLatencyThresholdLow"]) or 50) + 0.5)
							if low > mid then addon.db["squareMinimapStatsLatencyThresholdLow"] = mid end
							applySquareMinimapStatsNow(true)
						end,
						min = 0,
						max = 1000,
						step = 1,
						default = 150,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyColorLow",
						text = L["squareMinimapStatsColorLow"] or "Low color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyColorMid",
						text = L["squareMinimapStatsColorMid"] or "Medium color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyColorHigh",
						text = L["High color"] or "High color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyAnchor",
						text = L["Anchor"] or "Anchor",
						list = squareMinimapStatsAnchorOptions,
						order = squareMinimapStatsAnchorOrder,
						get = function() return addon.db and addon.db.squareMinimapStatsLatencyAnchor or "BOTTOMRIGHT" end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsLatencyAnchor"] = normalizeSquareMinimapAnchorSelection(value, maybeValue, "BOTTOMRIGHT")
							applySquareMinimapStatsNow(true)
						end,
						default = "BOTTOMRIGHT",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyOffsetX",
						text = L["Horizontal offset"] or "Horizontal offset",
						get = function() return addon.db and addon.db.squareMinimapStatsLatencyOffsetX or -3 end,
						set = function(value)
							addon.db["squareMinimapStatsLatencyOffsetX"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = -3,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyOffsetY",
						text = L["Vertical offset"] or "Vertical offset",
						get = function() return addon.db and addon.db.squareMinimapStatsLatencyOffsetY or 3 end,
						set = function(value)
							addon.db["squareMinimapStatsLatencyOffsetY"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = 3,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyFontSize",
						text = FONT_SIZE,
						get = function() return addon.db and addon.db.squareMinimapStatsLatencyFontSize or 12 end,
						set = function(value)
							addon.db["squareMinimapStatsLatencyFontSize"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 8,
						max = 32,
						step = 1,
						default = 12,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyUseClassColor",
						text = L["Use class color"] or "Use class color",
						func = function(value)
							addon.db["squareMinimapStatsLatencyUseClassColor"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = false,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLatency"),
						notify = "squareMinimapStatsLatency",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLatencyColor",
						text = L["Text color"] or "Text color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = function() return isSquareMinimapStatElementEnabled("squareMinimapStatsLatency")() and addon.db and addon.db.squareMinimapStatsLatencyUseClassColor ~= true end,
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
				},
			},
			{
				text = "",
				sType = "hint",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapStatsLocation",
				text = L["Location"] or "Location",
				func = function(key)
					addon.db["squareMinimapStatsLocation"] = key and true or false
					applySquareMinimapStatsNow(true)
				end,
				default = true,
				sType = "checkbox",
				parent = true,
				parentCheck = isSquareMinimapStatsEnabledSetting,
				notify = "enableSquareMinimapStats",
				parentSection = mapExpandable,
				children = {
					{
						var = "squareMinimapStatsLocationShowZone",
						text = L["squareMinimapStatsLocationShowZone"] or "Show zone",
						func = function(value)
							addon.db["squareMinimapStatsLocationShowZone"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = true,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLocation"),
						notify = "squareMinimapStatsLocation",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationShowSubzone",
						text = L["Show subzone"] or "Show subzone",
						func = function(value)
							addon.db["squareMinimapStatsLocationShowSubzone"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = false,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLocation"),
						notify = "squareMinimapStatsLocation",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationSubzoneBelowZone",
						text = L["squareMinimapStatsLocationSubzoneBelowZone"] or "Show subzone below zone",
						func = function(value)
							addon.db["squareMinimapStatsLocationSubzoneBelowZone"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = false,
						sType = "checkbox",
						parent = true,
						parentCheck = function()
							return isSquareMinimapStatElementEnabled("squareMinimapStatsLocation")
								and addon.db
								and addon.db.squareMinimapStatsLocationShowZone ~= false
								and addon.db.squareMinimapStatsLocationShowSubzone == true
						end,
						notify = "squareMinimapStatsLocation",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationUseZoneColor",
						text = L["Use zone color"] or "Use zone color",
						func = function(value)
							addon.db["squareMinimapStatsLocationUseZoneColor"] = value and true or false
							if value then addon.db["squareMinimapStatsLocationUseClassColor"] = false end
							applySquareMinimapStatsNow(true)
						end,
						default = true,
						sType = "checkbox",
						parent = true,
						parentCheck = function() return isSquareMinimapStatElementEnabled("squareMinimapStatsLocation")() and addon.db and addon.db.squareMinimapStatsLocationUseClassColor ~= true end,
						notify = "squareMinimapStatsLocation",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationAnchor",
						text = L["Anchor"] or "Anchor",
						list = squareMinimapStatsAnchorOptions,
						order = squareMinimapStatsAnchorOrder,
						get = function() return addon.db and addon.db.squareMinimapStatsLocationAnchor or "TOP" end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsLocationAnchor"] = normalizeSquareMinimapAnchorSelection(value, maybeValue, "TOP")
							applySquareMinimapStatsNow(true)
						end,
						default = "TOP",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLocation"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationOffsetX",
						text = L["Horizontal offset"] or "Horizontal offset",
						get = function() return addon.db and addon.db.squareMinimapStatsLocationOffsetX or 0 end,
						set = function(value)
							addon.db["squareMinimapStatsLocationOffsetX"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = 0,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLocation"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationOffsetY",
						text = L["Vertical offset"] or "Vertical offset",
						get = function() return addon.db and addon.db.squareMinimapStatsLocationOffsetY or -3 end,
						set = function(value)
							addon.db["squareMinimapStatsLocationOffsetY"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = -3,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLocation"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationFontSize",
						text = FONT_SIZE,
						get = function() return addon.db and addon.db.squareMinimapStatsLocationFontSize or 12 end,
						set = function(value)
							addon.db["squareMinimapStatsLocationFontSize"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 8,
						max = 32,
						step = 1,
						default = 12,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLocation"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationUseClassColor",
						text = L["Use class color"] or "Use class color",
						func = function(value)
							addon.db["squareMinimapStatsLocationUseClassColor"] = value and true or false
							if value then addon.db["squareMinimapStatsLocationUseZoneColor"] = false end
							applySquareMinimapStatsNow(true)
						end,
						default = false,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsLocation"),
						notify = "squareMinimapStatsLocation",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsLocationColor",
						text = L["Text color"] or "Text color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = function()
							return isSquareMinimapStatElementEnabled("squareMinimapStatsLocation")()
								and addon.db
								and addon.db.squareMinimapStatsLocationUseClassColor ~= true
								and addon.db.squareMinimapStatsLocationUseZoneColor ~= true
						end,
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
				},
			},
			{
				text = "",
				sType = "hint",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapStatsCoordinates",
				text = L["Coordinates"] or "Coordinates",
				func = function(key)
					addon.db["squareMinimapStatsCoordinates"] = key and true or false
					applySquareMinimapStatsNow(true)
				end,
				default = true,
				sType = "checkbox",
				parent = true,
				parentCheck = isSquareMinimapStatsEnabledSetting,
				notify = "enableSquareMinimapStats",
				parentSection = mapExpandable,
				children = {
					{
						var = "squareMinimapStatsCoordinatesHideInInstance",
						text = L["squareMinimapStatsCoordinatesHideInInstance"] or "Hide in instances",
						func = function(value)
							addon.db["squareMinimapStatsCoordinatesHideInInstance"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = true,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates"),
						notify = "squareMinimapStatsCoordinates",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsCoordinatesUpdateInterval",
						text = L["squareMinimapStatsUpdateInterval"] or "Update interval (s)",
						get = function() return addon.db and addon.db.squareMinimapStatsCoordinatesUpdateInterval or 0.2 end,
						set = function(value)
							addon.db["squareMinimapStatsCoordinatesUpdateInterval"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 0.1,
						max = 1.0,
						step = 0.05,
						default = 0.2,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsCoordinatesDecimals",
						text = L["squareMinimapStatsCoordinatesDecimals"] or "Precision (decimals)",
						get = function() return addon.db and addon.db.squareMinimapStatsCoordinatesDecimals or 2 end,
						set = function(value)
							addon.db["squareMinimapStatsCoordinatesDecimals"] = math.floor((tonumber(value) or 2) + 0.5)
							applySquareMinimapStatsNow(true)
						end,
						min = 0,
						max = 3,
						step = 1,
						default = 2,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsCoordinatesAnchor",
						text = L["Anchor"] or "Anchor",
						list = squareMinimapStatsAnchorOptions,
						order = squareMinimapStatsAnchorOrder,
						get = function() return addon.db and addon.db.squareMinimapStatsCoordinatesAnchor or "TOP" end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsCoordinatesAnchor"] = normalizeSquareMinimapAnchorSelection(value, maybeValue, "TOP")
							applySquareMinimapStatsNow(true)
						end,
						default = "TOP",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsCoordinatesOffsetX",
						text = L["Horizontal offset"] or "Horizontal offset",
						get = function() return addon.db and addon.db.squareMinimapStatsCoordinatesOffsetX or 0 end,
						set = function(value)
							addon.db["squareMinimapStatsCoordinatesOffsetX"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = 0,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsCoordinatesOffsetY",
						text = L["Vertical offset"] or "Vertical offset",
						get = function() return addon.db and addon.db.squareMinimapStatsCoordinatesOffsetY or -17 end,
						set = function(value)
							addon.db["squareMinimapStatsCoordinatesOffsetY"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = -17,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsCoordinatesFontSize",
						text = FONT_SIZE,
						get = function() return addon.db and addon.db.squareMinimapStatsCoordinatesFontSize or 12 end,
						set = function(value)
							addon.db["squareMinimapStatsCoordinatesFontSize"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 8,
						max = 32,
						step = 1,
						default = 12,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsCoordinatesUseClassColor",
						text = L["Use class color"] or "Use class color",
						func = function(value)
							addon.db["squareMinimapStatsCoordinatesUseClassColor"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = false,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates"),
						notify = "squareMinimapStatsCoordinates",
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsCoordinatesColor",
						text = L["Text color"] or "Text color",
						parent = true,
						default = false,
						sType = "colorpicker",
						parentCheck = function()
							return isSquareMinimapStatElementEnabled("squareMinimapStatsCoordinates")() and addon.db and addon.db.squareMinimapStatsCoordinatesUseClassColor ~= true
						end,
						callback = function() applySquareMinimapStatsNow(true) end,
						parentSection = mapExpandable,
					},
				},
			},
			{
				text = "",
				sType = "hint",
				parentSection = mapExpandable,
			},
			{
				var = "squareMinimapStatsTrackingButton",
				text = L["squareMinimapStatsTrackingButton"] or "Tracking Button",
				desc = L["squareMinimapStatsTrackingButtonDesc"]
					or "Moves the Blizzard tracking button onto the minimap as a configurable stats element and keeps the default tracking slot hidden while active.",
				func = function(key)
					addon.db["squareMinimapStatsTrackingButton"] = key and true or false
					applySquareMinimapStatsNow(true)
					if addon.functions.ApplyMinimapElementVisibility then addon.functions.ApplyMinimapElementVisibility() end
				end,
				default = false,
				sType = "checkbox",
				parent = true,
				parentCheck = isSquareMinimapStatsEnabledSetting,
				notify = "enableSquareMinimapStats",
				parentSection = mapExpandable,
				children = {
					{
						var = "squareMinimapStatsTrackingButtonAnchor",
						text = L["Anchor"] or "Anchor",
						list = squareMinimapStatsAnchorOptions,
						order = squareMinimapStatsAnchorOrder,
						get = function() return addon.db and addon.db.squareMinimapStatsTrackingButtonAnchor or "TOPLEFT" end,
						set = function(value, maybeValue)
							addon.db["squareMinimapStatsTrackingButtonAnchor"] = normalizeSquareMinimapAnchorSelection(value, maybeValue, "TOPLEFT")
							applySquareMinimapStatsNow(true)
						end,
						default = "TOPLEFT",
						sType = "dropdown",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTrackingButton"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTrackingButtonOffsetX",
						text = L["Horizontal offset"] or "Horizontal offset",
						get = function() return addon.db and addon.db.squareMinimapStatsTrackingButtonOffsetX or 3 end,
						set = function(value)
							addon.db["squareMinimapStatsTrackingButtonOffsetX"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = 3,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTrackingButton"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTrackingButtonOffsetY",
						text = L["Vertical offset"] or "Vertical offset",
						get = function() return addon.db and addon.db.squareMinimapStatsTrackingButtonOffsetY or -3 end,
						set = function(value)
							addon.db["squareMinimapStatsTrackingButtonOffsetY"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = -220,
						max = 220,
						step = 1,
						default = -3,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTrackingButton"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTrackingButtonShowBackground",
						text = L["squareMinimapStatsTrackingButtonShowBackground"] or "Show border/background",
						func = function(value)
							addon.db["squareMinimapStatsTrackingButtonShowBackground"] = value and true or false
							applySquareMinimapStatsNow(true)
						end,
						default = true,
						sType = "checkbox",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTrackingButton"),
						parentSection = mapExpandable,
					},
					{
						var = "squareMinimapStatsTrackingButtonScale",
						text = L["squareMinimapStatsTrackingButtonScale"] or "Button scale",
						get = function() return addon.db and addon.db.squareMinimapStatsTrackingButtonScale or 1.0 end,
						set = function(value)
							addon.db["squareMinimapStatsTrackingButtonScale"] = value
							applySquareMinimapStatsNow(true)
						end,
						min = 0.5,
						max = 2.0,
						step = 0.05,
						default = 1.0,
						sType = "slider",
						parent = true,
						parentCheck = isSquareMinimapStatElementEnabled("squareMinimapStatsTrackingButton"),
						parentSection = mapExpandable,
					},
				},
			},
		},
	},
}

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cMapNav, data)

addon.functions.SettingsCreateHeadline(cMapNav, L["MinimapButtonsAndCluster"] or "Minimap Buttons & Cluster", { parentSection = mapExpandable })

data = {
	{
		var = "minimapButtonsMouseover",
		text = L["minimapButtonsMouseover"],
		desc = L["minimapButtonsMouseoverDesc"],
		func = function(key)
			addon.db["minimapButtonsMouseover"] = key
			if addon.functions.applyMinimapButtonMouseover then addon.functions.applyMinimapButtonMouseover() end
		end,
		default = false,
		parentCheck = function()
			return not (
				addon.SettingsLayout.elements["enableMinimapButtonBin"]
				and addon.SettingsLayout.elements["enableMinimapButtonBin"].setting
				and addon.SettingsLayout.elements["enableMinimapButtonBin"].setting:GetValue() == true
			)
		end,
		notify = "enableMinimapButtonBin",
		parentSection = mapExpandable,
	},
	{
		var = "unclampMinimapCluster",
		text = L["unclampMinimapCluster"],
		desc = L["unclampMinimapClusterDesc"],
		func = function(key)
			addon.db["unclampMinimapCluster"] = key
			if addon.functions.applyMinimapClusterClamp then addon.functions.applyMinimapClusterClamp() end
		end,
		default = false,
		parentSection = mapExpandable,
	},
	{
		var = "enableMinimapClusterScale",
		text = L["enableMinimapClusterScale"],
		desc = L["enableMinimapClusterScaleDesc"],
		func = function(key)
			addon.db["enableMinimapClusterScale"] = key
			if addon.functions.applyMinimapClusterScale then addon.functions.applyMinimapClusterScale() end
		end,
		default = false,
		parentSection = mapExpandable,
		children = {
			{
				var = "minimapClusterScale",
				text = L["minimapClusterScale"],
				desc = L["minimapClusterScaleDesc"],
				parentCheck = function()
					return addon.SettingsLayout.elements["enableMinimapClusterScale"]
						and addon.SettingsLayout.elements["enableMinimapClusterScale"].setting
						and addon.SettingsLayout.elements["enableMinimapClusterScale"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.minimapClusterScale or 1 end,
				set = function(value)
					addon.db["minimapClusterScale"] = value
					if addon.functions.applyMinimapClusterScale then addon.functions.applyMinimapClusterScale() end
				end,
				min = 0.5,
				max = 2,
				step = 0.05,
				parent = true,
				default = 1,
				sType = "slider",
				parentSection = mapExpandable,
			},
		},
	},
	{
		var = "hideMinimapButton",
		text = L["Hide Minimap Button"],
		func = function(v)
			addon.db["hideMinimapButton"] = v
			addon.functions.toggleMinimapButton(addon.db["hideMinimapButton"])
		end,
		default = false,
		parentSection = mapExpandable,
	},
}

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cMapNav, data)

addon.functions.SettingsCreateMultiDropdown(cMapNav, {
	var = "hiddenMinimapElements",
	text = L["minimapHideElements"],
	parentSection = mapExpandable,
	options = {
		{ value = "Tracking", text = L["minimapHideElements_Tracking"] },
		{ value = "ZoneInfo", text = L["minimapHideElements_ZoneInfo"] },
		{ value = "Clock", text = L["minimapHideElements_Clock"] },
		{ value = "Calendar", text = L["Calendar"] },
		{ value = "Mail", text = L["minimapHideElements_Mail"] },
		{ value = "AddonCompartment", text = L["minimapHideElements_AddonCompartment"] },
	},
	callback = function()
		if addon.functions.ApplyMinimapElementVisibility then addon.functions.ApplyMinimapElementVisibility() end
	end,
})

addon.functions.SettingsCreateHeadline(cMapNav, L["LootspecAndLandingPage"] or "Lootspec & Landing Page", { parentSection = mapExpandable })

data = {
	{
		var = "enableLootspecQuickswitch",
		text = L["enableLootspecQuickswitch"],
		desc = L["enableLootspecQuickswitchDesc"],
		func = function(key)
			addon.db["enableLootspecQuickswitch"] = key
			if key then
				addon.functions.createLootspecFrame()
			else
				addon.functions.removeLootspecframe()
			end
		end,
		default = false,
		parentSection = mapExpandable,
	},
	{
		var = "enableLandingPageMenu",
		text = L["enableLandingPageMenu"],
		desc = L["enableLandingPageMenuDesc"],
		func = function(key) addon.db["enableLandingPageMenu"] = key end,
		default = false,
		parentSection = mapExpandable,
	},
}

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cMapNav, data)

addon.functions.SettingsCreateText(cMapNav, "|cff99e599" .. L["landingPageHide"] .. "|r", { parentSection = mapExpandable })

local function resolveLandingPageId(value)
	if type(value) == "number" then return value end
	if type(value) == "string" then
		local reverse = addon.variables and addon.variables.landingPageReverse
		return (reverse and reverse[value]) or tonumber(value)
	end
end

local function normalizeHiddenLandingPages()
	addon.db.hiddenLandingPages = addon.db.hiddenLandingPages or {}
	local toClear = {}
	for key, flag in pairs(addon.db.hiddenLandingPages) do
		if type(key) ~= "number" then
			local resolved = resolveLandingPageId(key)
			if resolved then
				addon.db.hiddenLandingPages[resolved] = flag and true or nil
				table.insert(toClear, key)
			end
		end
	end
	for _, key in ipairs(toClear) do
		addon.db.hiddenLandingPages[key] = nil
	end
end

normalizeHiddenLandingPages()

local function getIgnoreStateLandingPage(value)
	if not value then return false end
	addon.db.hiddenLandingPages = addon.db.hiddenLandingPages or {}
	local resolved = resolveLandingPageId(value)
	if not resolved then return false end
	return addon.db.hiddenLandingPages[resolved] and true or false
end

local function setIgnoreStateLandingPage(value, shouldSelect)
	if not value then return end
	addon.db.hiddenLandingPages = addon.db.hiddenLandingPages or {}
	local resolved = resolveLandingPageId(value)
	if not resolved then return end
	if shouldSelect then
		addon.db.hiddenLandingPages[resolved] = true
	else
		addon.db.hiddenLandingPages[resolved] = nil
	end
	local page = addon.variables and addon.variables.landingPageType and addon.variables.landingPageType[resolved]
	if page and addon.functions.toggleLandingPageButton then addon.functions.toggleLandingPageButton(page.title, shouldSelect) end
end

addon.functions.SettingsCreateMultiDropdown(cMapNav, {
	var = "hiddenLandingPages",
	text = HIDE,
	parentSection = mapExpandable,
	optionfunc = function()
		local buttons = (addon.variables and addon.variables.landingPageType) or {}
		local list = {}
		for id in pairs(buttons) do
			table.insert(list, { value = id, text = buttons[id].title })
		end
		table.sort(list, function(a, b) return tostring(a.text) < tostring(b.text) end)
		return list
	end,
	isSelectedFunc = getIgnoreStateLandingPage,
	setSelectedFunc = setIgnoreStateLandingPage,
})

addon.functions.SettingsCreateHeadline(cMapNav, L["InstanceDifficultyIndicator"] or "Instance Difficulty Indicator", { parentSection = mapExpandable })

data = {
	{
		var = "showInstanceDifficulty",
		text = L["showInstanceDifficulty"],
		desc = L["showInstanceDifficultyDesc"],
		func = function(key)
			addon.db["showInstanceDifficulty"] = key
			if addon.InstanceDifficulty and addon.InstanceDifficulty.SetEnabled then addon.InstanceDifficulty:SetEnabled(key) end
		end,
		default = false,
		parentSection = mapExpandable,
		children = {
			{
				var = "instanceDifficultyFontSize",
				text = L["instanceDifficultyFontSize"],
				parentCheck = function()
					return addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.instanceDifficultyFontSize or 1 end,
				set = function(value)
					addon.db["instanceDifficultyFontSize"] = value
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				min = 8,
				max = 28,
				step = 1,
				parent = true,
				default = 14,
				sType = "slider",
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyAnchor",
				text = L["Anchor"] or "Anchor",
				list = instanceDifficultyAnchorOptions,
				order = squareMinimapStatsAnchorOrder,
				parentCheck = function()
					return addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				get = function() return normalizeSquareMinimapAnchorSelection(addon.db and addon.db.instanceDifficultyAnchor, nil, "CENTER") end,
				set = function(value, maybeValue)
					addon.db["instanceDifficultyAnchor"] = normalizeSquareMinimapAnchorSelection(value, maybeValue, "CENTER")
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				default = "CENTER",
				sType = "dropdown",
				parent = true,
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyOffsetX",
				text = L["Horizontal offset"],
				parentCheck = function()
					return addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.instanceDifficultyOffsetX or 0 end,
				set = function(value)
					addon.db["instanceDifficultyOffsetX"] = value
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				min = -400,
				max = 400,
				step = 1,
				parent = true,
				default = 0,
				sType = "slider",
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyOffsetY",
				text = L["Vertical offset"],
				parentCheck = function()
					return addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				get = function() return addon.db and addon.db.instanceDifficultyOffsetY or 0 end,
				set = function(value)
					addon.db["instanceDifficultyOffsetY"] = value
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				min = -400,
				max = 400,
				step = 1,
				parent = true,
				default = 0,
				sType = "slider",
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyUseColors",
				text = L["instanceDifficultyUseColors"],
				func = function(key)
					addon.db["instanceDifficultyUseColors"] = key
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				parent = true,
				notify = "showInstanceDifficulty",
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyColors",
				subvar = "LFR",
				hasOpacity = true,
				text = _G["PLAYER_DIFFICULTY3"],
				parentCheck = function()
					return addon.SettingsLayout.elements["instanceDifficultyUseColors"]
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting:GetValue() == true
						and addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				sType = "colorpicker",
				callback = function()
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyColors",
				subvar = "NM",
				hasOpacity = true,
				text = _G["PLAYER_DIFFICULTY1"],
				parentCheck = function()
					return addon.SettingsLayout.elements["instanceDifficultyUseColors"]
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting:GetValue() == true
						and addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				sType = "colorpicker",
				callback = function()
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyColors",
				subvar = "HC",
				hasOpacity = true,
				text = _G["PLAYER_DIFFICULTY2"],
				parentCheck = function()
					return addon.SettingsLayout.elements["instanceDifficultyUseColors"]
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting:GetValue() == true
						and addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				sType = "colorpicker",
				callback = function()
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyColors",
				subvar = "M",
				hasOpacity = true,
				text = _G["PLAYER_DIFFICULTY6"],
				parentCheck = function()
					return addon.SettingsLayout.elements["instanceDifficultyUseColors"]
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting:GetValue() == true
						and addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				sType = "colorpicker",
				callback = function()
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyColors",
				subvar = "MPLUS",
				hasOpacity = true,
				text = _G["PLAYER_DIFFICULTY_MYTHIC_PLUS"],
				parentCheck = function()
					return addon.SettingsLayout.elements["instanceDifficultyUseColors"]
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting:GetValue() == true
						and addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				sType = "colorpicker",
				callback = function()
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				parentSection = mapExpandable,
			},
			{
				var = "instanceDifficultyColors",
				subvar = "TW",
				hasOpacity = true,
				text = _G["PLAYER_DIFFICULTY_TIMEWALKER"],
				parentCheck = function()
					return addon.SettingsLayout.elements["instanceDifficultyUseColors"]
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting
						and addon.SettingsLayout.elements["instanceDifficultyUseColors"].setting:GetValue() == true
						and addon.SettingsLayout.elements["showInstanceDifficulty"]
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting
						and addon.SettingsLayout.elements["showInstanceDifficulty"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				sType = "colorpicker",
				callback = function()
					if addon.InstanceDifficulty then addon.InstanceDifficulty:Update() end
				end,
				parentSection = mapExpandable,
			},
		},
	},
}

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cMapNav, data)

addon.functions.SettingsCreateHeadline(cMapNav, L["MinimapButtonBin"] or "Minimap Button Bin", { parentSection = mapExpandable })
local buttonSinkSection = mapExpandable

local function isButtonSinkSettingEnabled(key)
	return addon.SettingsLayout.elements[key] and addon.SettingsLayout.elements[key].setting and addon.SettingsLayout.elements[key].setting:GetValue() == true
end

local function isMinimapButtonBinEnabled() return isButtonSinkSettingEnabled("enableMinimapButtonBin") end

local function isButtonSinkIconModeEnabled() return isMinimapButtonBinEnabled() and isButtonSinkSettingEnabled("useMinimapButtonBinIcon") end

local function isDetachedButtonSinkIconModeEnabled() return isMinimapButtonBinEnabled() and isButtonSinkSettingEnabled("useDetachedMinimapButtonBinIcon") end

local function isButtonSinkHoverModeEnabled() return isMinimapButtonBinEnabled() and isButtonSinkSettingEnabled("useMinimapButtonBinMouseover") end

local function isButtonSinkLauncherModeEnabled() return isButtonSinkIconModeEnabled() or isDetachedButtonSinkIconModeEnabled() end

data = {
	{
		var = "enableMinimapButtonBin",
		text = L["enableMinimapButtonBin"],
		desc = L["enableMinimapButtonBinDesc"],
		func = function(key)
			addon.db["enableMinimapButtonBin"] = key
			addon.functions.toggleButtonSink()
			if addon.functions.applyMinimapButtonMouseover then addon.functions.applyMinimapButtonMouseover() end
		end,
		default = false,
		parentSection = buttonSinkSection,
		children = {
			{
				var = "useMinimapButtonBinIcon",
				text = L["useMinimapButtonBinIcon"],
				desc = L["useMinimapButtonBinIconDesc"],
				func = function(key)
					addon.db["useMinimapButtonBinIcon"] = key
					if key then
						addon.db["useMinimapButtonBinMouseover"] = false
						addon.db["useDetachedMinimapButtonBinIcon"] = false
					end
					addon.functions.toggleButtonSink()
				end,
				default = false,
				sType = "checkbox",
				parentCheck = function() return isMinimapButtonBinEnabled() and not isButtonSinkHoverModeEnabled() and not isDetachedButtonSinkIconModeEnabled() end,
				parent = true,
				notify = "enableMinimapButtonBin",
				parentSection = buttonSinkSection,
			},
			{
				var = "useDetachedMinimapButtonBinIcon",
				text = L["useDetachedMinimapButtonBinIcon"],
				desc = L["useDetachedMinimapButtonBinIconDesc"],
				func = function(key)
					addon.db["useDetachedMinimapButtonBinIcon"] = key
					if key then
						addon.db["useMinimapButtonBinMouseover"] = false
						addon.db["useMinimapButtonBinIcon"] = false
					end
					addon.functions.toggleButtonSink()
				end,
				default = false,
				sType = "checkbox",
				parentCheck = function() return isMinimapButtonBinEnabled() and not isButtonSinkHoverModeEnabled() and not isButtonSinkIconModeEnabled() end,
				parent = true,
				notify = "enableMinimapButtonBin",
				parentSection = buttonSinkSection,
			},
			{
				var = "detachedButtonSinkScale",
				text = L["detachedButtonSinkScale"],
				desc = L["detachedButtonSinkScaleDesc"],
				get = function() return addon.db and addon.db.detachedButtonSinkScale or 1 end,
				set = function(value)
					addon.db["detachedButtonSinkScale"] = value
					if addon.functions.applyDetachedButtonSinkScale then addon.functions.applyDetachedButtonSinkScale() end
				end,
				min = 0.5,
				max = 2.5,
				step = 0.05,
				parent = true,
				default = 1,
				sType = "slider",
				parentCheck = isDetachedButtonSinkIconModeEnabled,
				parentSection = buttonSinkSection,
			},
			{
				var = "detachedButtonSinkMoveModifier",
				text = L["detachedButtonSinkMoveModifier"],
				desc = L["detachedButtonSinkMoveModifierDesc"],
				list = {
					NONE = NONE,
					ALT = ALT_KEY_TEXT,
					SHIFT = SHIFT_KEY_TEXT,
					CTRL = CTRL_KEY_TEXT,
				},
				order = { "NONE", "ALT", "SHIFT", "CTRL" },
				default = "ALT",
				get = function() return addon.db and addon.db.detachedButtonSinkMoveModifier or "ALT" end,
				set = function(value)
					local valid = {
						NONE = true,
						ALT = true,
						SHIFT = true,
						CTRL = true,
					}
					if not valid[value] then value = "ALT" end
					addon.db["detachedButtonSinkMoveModifier"] = value
				end,
				parent = true,
				parentCheck = isDetachedButtonSinkIconModeEnabled,
				sType = "dropdown",
				parentSection = buttonSinkSection,
			},
			{
				var = "buttonSinkAnchorPreference",
				text = L["minimapButtonBinAnchor"],
				desc = L["minimapButtonBinAnchorDesc"],
				list = {
					AUTO = L["Auto"],
					TOP = L["Top"],
					TOPLEFT = L["Top left"],
					TOPRIGHT = L["Top right"],
					LEFT = L["Left"],
					RIGHT = L["Right"],
					BOTTOMLEFT = L["Bottom left"],
					BOTTOMRIGHT = L["Bottom right"],
					BOTTOM = L["Bottom"],
				},
				order = {
					"AUTO",
					"TOPLEFT",
					"TOP",
					"TOPRIGHT",
					"LEFT",
					"RIGHT",
					"BOTTOMLEFT",
					"BOTTOM",
					"BOTTOMRIGHT",
				},
				default = "AUTO",
				get = function() return addon.db and addon.db.buttonSinkAnchorPreference or "AUTO" end,
				set = function(value)
					local valid = {
						AUTO = true,
						TOP = true,
						TOPLEFT = true,
						TOPRIGHT = true,
						LEFT = true,
						RIGHT = true,
						BOTTOMLEFT = true,
						BOTTOMRIGHT = true,
						BOTTOM = true,
					}
					if not valid[value] then value = "AUTO" end
					addon.db["buttonSinkAnchorPreference"] = value
				end,
				parent = true,
				parentCheck = isButtonSinkLauncherModeEnabled,
				notify = "enableMinimapButtonBin",
				sType = "dropdown",
				parentSection = buttonSinkSection,
			},
			{
				var = "minimapButtonBinIconClickToggle",
				text = L["minimapButtonBinIconClickToggle"],
				desc = L["minimapButtonBinIconClickToggleDesc"],
				func = function(key)
					addon.db["minimapButtonBinIconClickToggle"] = key
					addon.functions.toggleButtonSink()
				end,
				default = false,
				sType = "checkbox",
				parentCheck = isButtonSinkLauncherModeEnabled,
				parent = true,
				notify = "enableMinimapButtonBin",
				parentSection = buttonSinkSection,
			},
			{
				var = "useMinimapButtonBinMouseover",
				text = L["useMinimapButtonBinMouseover"],
				desc = L["useMinimapButtonBinMouseoverDesc"],
				func = function(key)
					addon.db["useMinimapButtonBinMouseover"] = key
					if key then
						addon.db["useMinimapButtonBinIcon"] = false
						addon.db["useDetachedMinimapButtonBinIcon"] = false
					end
					addon.functions.toggleButtonSink()
				end,
				default = false,
				sType = "checkbox",
				parentCheck = function() return isMinimapButtonBinEnabled() and not isButtonSinkIconModeEnabled() and not isDetachedButtonSinkIconModeEnabled() end,
				parent = true,
				notify = "enableMinimapButtonBin",
				parentSection = buttonSinkSection,
			},
			{
				var = "lockMinimapButtonBin",
				text = L["lockMinimapButtonBin"],
				desc = L["lockMinimapButtonBinDesc"],
				func = function(key)
					addon.db["lockMinimapButtonBin"] = key
					addon.functions.toggleButtonSink()
				end,
				default = false,
				sType = "checkbox",
				parentCheck = function() return isMinimapButtonBinEnabled() and (isButtonSinkHoverModeEnabled() or isDetachedButtonSinkIconModeEnabled()) end,
				parent = true,
				notify = "enableMinimapButtonBin",
				parentSection = buttonSinkSection,
			},
			{
				var = "minimapButtonBinHideBorder",
				text = L["Hide border"],
				desc = L["minimapButtonBinHideBorderDesc"],
				func = function(key)
					addon.db["minimapButtonBinHideBorder"] = key
					addon.functions.toggleButtonSink()
				end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["enableMinimapButtonBin"]
						and addon.SettingsLayout.elements["enableMinimapButtonBin"].setting
						and addon.SettingsLayout.elements["enableMinimapButtonBin"].setting:GetValue() == true
				end,
				parent = true,
				parentSection = buttonSinkSection,
			},
			{
				var = "minimapButtonBinHideBackground",
				text = L["minimapButtonBinHideBackground"],
				desc = L["minimapButtonBinHideBackgroundDesc"],
				func = function(key)
					addon.db["minimapButtonBinHideBackground"] = key
					if addon.functions.applyButtonSinkAppearance then addon.functions.applyButtonSinkAppearance() end
				end,
				default = false,
				sType = "checkbox",
				parentCheck = function()
					return addon.SettingsLayout.elements["enableMinimapButtonBin"]
						and addon.SettingsLayout.elements["enableMinimapButtonBin"].setting
						and addon.SettingsLayout.elements["enableMinimapButtonBin"].setting:GetValue() == true
				end,
				parent = true,
				parentSection = buttonSinkSection,
			},
			{
				var = "minimapButtonBinColumns",
				text = L["minimapButtonBinColumns"],
				desc = L["minimapButtonBinColumnsDesc"],
				set = function(val)
					val = math.floor(val + 0.5)
					if val < 1 then
						val = 1
					elseif val > 99 then
						val = 99
					end
					addon.db["minimapButtonBinColumns"] = val
					addon.functions.LayoutButtons()
				end,
				sType = "slider",
				parentCheck = function()
					return addon.SettingsLayout.elements["enableMinimapButtonBin"]
						and addon.SettingsLayout.elements["enableMinimapButtonBin"].setting
						and addon.SettingsLayout.elements["enableMinimapButtonBin"].setting:GetValue() == true
				end,
				parent = true,
				min = 1,
				max = 99,
				step = 1,
				default = 4,
				parentSection = buttonSinkSection,
			},
			{
				text = "|cff99e599" .. L["ignoreMinimapSinkHole"] .. "|r",
				sType = "hint",
				parentSection = buttonSinkSection,
			},
		},
	},
}

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cMapNav, data)

local function getIgnoreState(value)
	if not value then return false end
	return (addon.db["ignoreMinimapSinkHole_" .. value] or addon.db["ignoreMinimapButtonBin_" .. value]) and true or false
end

local function setIgnoreState(value, shouldSelect)
	if not value then return end
	if shouldSelect then
		addon.db["ignoreMinimapSinkHole_" .. value] = true
		addon.db["ignoreMinimapButtonBin_" .. value] = true
	else
		addon.db["ignoreMinimapSinkHole_" .. value] = nil
		addon.db["ignoreMinimapButtonBin_" .. value] = nil
	end
	if addon.functions.LayoutButtons then addon.functions.LayoutButtons() end
end

addon.functions.SettingsCreateMultiDropdown(cMapNav, {
	var = "ignoreMinimapSinkHole",
	text = L["Exclude"] or IGNORE,
	parent = true,
	element = addon.SettingsLayout.elements["enableMinimapButtonBin"] and addon.SettingsLayout.elements["enableMinimapButtonBin"].element,
	parentCheck = isMinimapButtonBinEnabled,
	parentSection = buttonSinkSection,
	optionfunc = function()
		local buttons = (addon.variables and addon.variables.bagButtonState) or {}
		local list = {}
		for name in pairs(buttons) do
			local label = tostring(name)
			table.insert(list, { value = name, text = label })
		end
		table.sort(list, function(a, b) return tostring(a.text) < tostring(b.text) end)
		return list
	end,
	isSelectedFunc = getIgnoreState,
	setSelectedFunc = setIgnoreState,
})

----- REGION END

local WORLD_MAP_COORD_DEFAULT_INTERVAL = 0.1

local function getWorldMapCoordInterval()
	local v = addon.db and addon.db.worldMapCoordinatesUpdateInterval
	if type(v) ~= "number" then v = WORLD_MAP_COORD_DEFAULT_INTERVAL end
	if v < 0.01 then v = 0.01 end
	if v > 1.00 then v = 1.00 end
	return v
end

local function ensureWorldMapCoordFrames()
	addon.variables = addon.variables or {}
	local container = WorldMapFrame and WorldMapFrame.BorderFrame and WorldMapFrame.BorderFrame.TitleContainer
	if not container then return nil end

	if not addon.variables.worldMapPlayerCoords then
		addon.variables.worldMapPlayerCoords = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	elseif addon.variables.worldMapPlayerCoords:GetParent() ~= container then
		addon.variables.worldMapPlayerCoords:SetParent(container)
	end

	if not addon.variables.worldMapCursorCoords then
		addon.variables.worldMapCursorCoords = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	elseif addon.variables.worldMapCursorCoords:GetParent() ~= container then
		addon.variables.worldMapCursorCoords:SetParent(container)
	end

	return true
end

local function applyWorldMapCoordLayout(showCursor)
	if not ensureWorldMapCoordFrames() then return end
	local key = tostring(showCursor)
	if addon.variables.worldMapCoordLayoutKey == key then return end
	addon.variables.worldMapCoordLayoutKey = key

	local container = WorldMapFrame and WorldMapFrame.BorderFrame and WorldMapFrame.BorderFrame.TitleContainer
	if not container then return end

	local player = addon.variables.worldMapPlayerCoords
	local cursor = addon.variables.worldMapCursorCoords
	if not player or not cursor then return end

	player:ClearAllPoints()
	cursor:ClearAllPoints()

	if showCursor then
		player:SetPoint("RIGHT", container, "RIGHT", -200, 0)
		player:SetJustifyH("LEFT")
		cursor:SetPoint("RIGHT", container, "RIGHT", -40, 0)
		cursor:SetJustifyH("RIGHT")
	else
		player:SetPoint("RIGHT", container, "RIGHT", -40, 0)
		player:SetJustifyH("RIGHT")
	end
end

local function formatCoords(x, y)
	if not x or not y then return nil end
	return string.format("%.2f, %.2f", x * 100, y * 100)
end

local function getPlayerCoords()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return nil end
	if IsInInstance() then return nil end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then return nil end
	return pos.x, pos.y
end

local function getCursorCoords()
	if not WorldMapFrame or not WorldMapFrame.ScrollContainer or not WorldMapFrame.ScrollContainer.GetNormalizedCursorPosition then return nil end
	if addon.db and addon.db.worldMapCoordinatesHideCursor then
		if WorldMapFrame.ScrollContainer.IsMouseOver and not WorldMapFrame.ScrollContainer:IsMouseOver() then return nil end
	end
	local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
	if not x or not y or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
	return x, y
end

local function updateWorldMapCoordinates()
	if not addon.db or not addon.db["showWorldMapCoordinates"] then return end
	if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
	if not ensureWorldMapCoordFrames() then return end

	local px, py = getPlayerCoords()
	local cx, cy = getCursorCoords()

	local playerText = formatCoords(px, py)
	local cursorText = formatCoords(cx, cy)
	local showCursor = cursorText ~= nil and cursorText ~= ""

	applyWorldMapCoordLayout(showCursor)

	if addon.variables.worldMapPlayerCoords then addon.variables.worldMapPlayerCoords:SetText(playerText and (PLAYER .. ": " .. playerText) or "") end
	if addon.variables.worldMapCursorCoords then
		local cursorLabel = MOUSE_LABEL
		addon.variables.worldMapCursorCoords:SetText(showCursor and (cursorLabel .. ": " .. cursorText) or "")
	end
end

local function startWorldMapCoordinates()
	if addon.variables.worldMapCoordTicker or not addon.db or not addon.db["showWorldMapCoordinates"] then return end
	updateWorldMapCoordinates()
	addon.variables.worldMapCoordTicker = C_Timer.NewTicker(getWorldMapCoordInterval(), function()
		if not addon.db or not addon.db["showWorldMapCoordinates"] then
			addon.functions.DisableWorldMapCoordinates()
			return
		end
		if WorldMapFrame and WorldMapFrame:IsShown() then updateWorldMapCoordinates() end
	end)
end

function addon.functions.DisableWorldMapCoordinates()
	if addon.variables.worldMapCoordTicker then
		addon.variables.worldMapCoordTicker:Cancel()
		addon.variables.worldMapCoordTicker = nil
		addon.variables.worldMapCoordLayoutKey = nil
		if addon.variables.worldMapPlayerCoords then addon.variables.worldMapPlayerCoords:SetText("") end
		if addon.variables.worldMapCursorCoords then addon.variables.worldMapCursorCoords:SetText("") end
	end
end

local function ensureWorldMapHooks()
	if addon.variables.worldMapCoordsHooked or not WorldMapFrame then return end
	WorldMapFrame:HookScript("OnShow", function()
		if addon.db and addon.db["showWorldMapCoordinates"] then startWorldMapCoordinates() end
	end)
	WorldMapFrame:HookScript("OnHide", addon.functions.DisableWorldMapCoordinates)
	addon.variables.worldMapCoordsHooked = true
end

function addon.functions.EnableWorldMapCoordinates()
	if not addon.db or not addon.db["showWorldMapCoordinates"] then return end
	ensureWorldMapHooks()
	if WorldMapFrame and WorldMapFrame:IsShown() then startWorldMapCoordinates() end
end

refreshWorldMapCoordinates = function(restartTicker)
	if not addon.db or not addon.db["showWorldMapCoordinates"] then return end
	if restartTicker then
		addon.functions.DisableWorldMapCoordinates()
		addon.functions.EnableWorldMapCoordinates()
		return
	end
	if WorldMapFrame and WorldMapFrame:IsShown() then updateWorldMapCoordinates() end
end

local function applySquareMinimapLayout(self, underneath)
	if not addon.db or not addon.db.enableSquareMinimap or not addon.db.enableSquareMinimapLayout then return end
	if not Minimap or not MinimapCluster or not Minimap.ZoomIn or not Minimap.ZoomOut then return end

	local addonCompartment = _G.AddonCompartmentFrame
	local instanceDifficulty = MinimapCluster and MinimapCluster.InstanceDifficulty
	local indicatorFrame = MinimapCluster and MinimapCluster.IndicatorFrame

	local headerUnderneath = underneath
	if headerUnderneath == nil then
		local headerSetting = Enum and Enum.EditModeMinimapSetting and Enum.EditModeMinimapSetting.HeaderUnderneath
		if headerSetting and MinimapCluster.GetSettingValueBool and MinimapCluster.IsInitialized and MinimapCluster:IsInitialized() then
			headerUnderneath = MinimapCluster:GetSettingValueBool(headerSetting)
		else
			headerUnderneath = false
		end
	end

	Minimap:ClearAllPoints()
	Minimap.ZoomIn:ClearAllPoints()
	Minimap.ZoomOut:ClearAllPoints()
	if indicatorFrame then indicatorFrame:ClearAllPoints() end
	if addonCompartment then addonCompartment:ClearAllPoints() end
	if instanceDifficulty then instanceDifficulty:ClearAllPoints() end

	if not headerUnderneath then
		Minimap:SetPoint("TOP", MinimapCluster, "TOP", 14, -25)
		if instanceDifficulty then instanceDifficulty:SetPoint("TOPRIGHT", MinimapCluster, "TOPRIGHT", -16, -25) end

		Minimap.ZoomIn:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
		Minimap.ZoomOut:SetPoint("RIGHT", Minimap.ZoomIn, "LEFT", -6, 0)
		if addonCompartment then addonCompartment:SetPoint("BOTTOM", Minimap.ZoomIn, "BOTTOM", 0, 20) end
	else
		Minimap:SetPoint("BOTTOM", MinimapCluster, "BOTTOM", 14, 25)
		if instanceDifficulty then instanceDifficulty:SetPoint("BOTTOMRIGHT", MinimapCluster, "BOTTOMRIGHT", -16, 22) end

		Minimap.ZoomIn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
		Minimap.ZoomOut:SetPoint("RIGHT", Minimap.ZoomIn, "LEFT", -6, 0)
		if addonCompartment then addonCompartment:SetPoint("TOP", Minimap.ZoomIn, "TOP", 0, -20) end
	end
	if indicatorFrame then indicatorFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2) end

	if addonCompartment then addonCompartment:SetFrameStrata("MEDIUM") end
end

function addon.functions.applySquareMinimapLayout(forceUnderneath)
	addon.variables = addon.variables or {}
	applySquareMinimapLayout(nil, forceUnderneath)
	if addon.db and addon.db.enableSquareMinimap and addon.db.enableSquareMinimapLayout and MinimapCluster and not addon.variables.squareMinimapLayoutHooked then
		hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", applySquareMinimapLayout)
		addon.variables.squareMinimapLayoutHooked = true
	end
	if not addon.variables.squareMinimapIndicatorHooked and type(_G.MiniMapIndicatorFrame_UpdatePosition) == "function" then
		hooksecurefunc("MiniMapIndicatorFrame_UpdatePosition", function()
			if not addon.db or not addon.db.enableSquareMinimap or not addon.db.enableSquareMinimapLayout then return end
			if not Minimap or not MinimapCluster or not MinimapCluster.IndicatorFrame then return end
			MinimapCluster.IndicatorFrame:ClearAllPoints()
			MinimapCluster.IndicatorFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
		end)
		addon.variables.squareMinimapIndicatorHooked = true
	end
end

local function copyDefaultValue(value)
	if type(value) ~= "table" then return value end
	local out = {}
	for key, subValue in pairs(value) do
		out[key] = copyDefaultValue(subValue)
	end
	return out
end

local squareMinimapStatsDefaults = {
	enableSquareMinimapStats = false,
	squareMinimapStatsFont = getGlobalFontConfigKey(),
	squareMinimapStatsOutline = getGlobalFontStyleConfigKey(),
	squareMinimapStatsTime = true,
	squareMinimapStatsTimeAnchor = "BOTTOMLEFT",
	squareMinimapStatsTimeOffsetX = 3,
	squareMinimapStatsTimeOffsetY = 17,
	squareMinimapStatsTimeFontSize = 18,
	squareMinimapStatsTimeColor = { r = 1, g = 1, b = 1, a = 1 },
	squareMinimapStatsTimeUseClassColor = false,
	squareMinimapStatsTimeDisplayMode = "server",
	squareMinimapStatsTimeUse24Hour = true,
	squareMinimapStatsTimeShowSeconds = false,
	squareMinimapStatsTimeLeftClickAction = "calendar",
	squareMinimapStatsFPS = true,
	squareMinimapStatsFPSAnchor = "BOTTOMLEFT",
	squareMinimapStatsFPSOffsetX = 3,
	squareMinimapStatsFPSOffsetY = 3,
	squareMinimapStatsFPSFontSize = 12,
	squareMinimapStatsFPSColor = { r = 1, g = 1, b = 1, a = 1 },
	squareMinimapStatsFPSUseClassColor = false,
	squareMinimapStatsFPSThresholdMedium = 30,
	squareMinimapStatsFPSThresholdHigh = 60,
	squareMinimapStatsFPSColorLow = { r = 1, g = 0, b = 0, a = 1 },
	squareMinimapStatsFPSColorMid = { r = 1, g = 1, b = 0, a = 1 },
	squareMinimapStatsFPSColorHigh = { r = 0, g = 1, b = 0, a = 1 },
	squareMinimapStatsFPSUpdateInterval = 0.25,
	squareMinimapStatsLatency = true,
	squareMinimapStatsLatencyAnchor = "BOTTOMRIGHT",
	squareMinimapStatsLatencyOffsetX = -3,
	squareMinimapStatsLatencyOffsetY = 3,
	squareMinimapStatsLatencyFontSize = 12,
	squareMinimapStatsLatencyColor = { r = 1, g = 1, b = 1, a = 1 },
	squareMinimapStatsLatencyUseClassColor = false,
	squareMinimapStatsLatencyMode = "max",
	squareMinimapStatsLatencyThresholdLow = 50,
	squareMinimapStatsLatencyThresholdMid = 150,
	squareMinimapStatsLatencyColorLow = { r = 0, g = 1, b = 0, a = 1 },
	squareMinimapStatsLatencyColorMid = { r = 1, g = 0.65, b = 0, a = 1 },
	squareMinimapStatsLatencyColorHigh = { r = 1, g = 0, b = 0, a = 1 },
	squareMinimapStatsLatencyUpdateInterval = 1.0,
	squareMinimapStatsLocation = true,
	squareMinimapStatsLocationAnchor = "TOP",
	squareMinimapStatsLocationOffsetX = 0,
	squareMinimapStatsLocationOffsetY = -3,
	squareMinimapStatsLocationFontSize = 12,
	squareMinimapStatsLocationColor = { r = 1, g = 1, b = 1, a = 1 },
	squareMinimapStatsLocationUseClassColor = false,
	squareMinimapStatsLocationShowZone = true,
	squareMinimapStatsLocationShowSubzone = false,
	squareMinimapStatsLocationSubzoneBelowZone = false,
	squareMinimapStatsLocationUseZoneColor = true,
	squareMinimapStatsCoordinates = true,
	squareMinimapStatsCoordinatesAnchor = "TOP",
	squareMinimapStatsCoordinatesOffsetX = 0,
	squareMinimapStatsCoordinatesOffsetY = -17,
	squareMinimapStatsCoordinatesFontSize = 12,
	squareMinimapStatsCoordinatesColor = { r = 1, g = 1, b = 1, a = 1 },
	squareMinimapStatsCoordinatesUseClassColor = false,
	squareMinimapStatsCoordinatesHideInInstance = true,
	squareMinimapStatsCoordinatesDecimals = 2,
	squareMinimapStatsCoordinatesUpdateInterval = 0.2,
	squareMinimapStatsTrackingButton = false,
	squareMinimapStatsTrackingButtonAnchor = "TOPLEFT",
	squareMinimapStatsTrackingButtonOffsetX = 3,
	squareMinimapStatsTrackingButtonOffsetY = -3,
	squareMinimapStatsTrackingButtonShowBackground = true,
	squareMinimapStatsTrackingButtonScale = 1.0,
}

local squareMinimapStatsConfig = {
	time = {
		enabledKey = "squareMinimapStatsTime",
		anchorKey = "squareMinimapStatsTimeAnchor",
		offsetXKey = "squareMinimapStatsTimeOffsetX",
		offsetYKey = "squareMinimapStatsTimeOffsetY",
		fontSizeKey = "squareMinimapStatsTimeFontSize",
		colorKey = "squareMinimapStatsTimeColor",
		useClassColorKey = "squareMinimapStatsTimeUseClassColor",
		anchorPoint = "BOTTOMLEFT",
	},
	fps = {
		enabledKey = "squareMinimapStatsFPS",
		anchorKey = "squareMinimapStatsFPSAnchor",
		offsetXKey = "squareMinimapStatsFPSOffsetX",
		offsetYKey = "squareMinimapStatsFPSOffsetY",
		fontSizeKey = "squareMinimapStatsFPSFontSize",
		colorKey = "squareMinimapStatsFPSColor",
		useClassColorKey = "squareMinimapStatsFPSUseClassColor",
		anchorPoint = "BOTTOMLEFT",
	},
	latency = {
		enabledKey = "squareMinimapStatsLatency",
		anchorKey = "squareMinimapStatsLatencyAnchor",
		offsetXKey = "squareMinimapStatsLatencyOffsetX",
		offsetYKey = "squareMinimapStatsLatencyOffsetY",
		fontSizeKey = "squareMinimapStatsLatencyFontSize",
		colorKey = "squareMinimapStatsLatencyColor",
		useClassColorKey = "squareMinimapStatsLatencyUseClassColor",
		anchorPoint = "BOTTOMRIGHT",
	},
	location = {
		enabledKey = "squareMinimapStatsLocation",
		anchorKey = "squareMinimapStatsLocationAnchor",
		offsetXKey = "squareMinimapStatsLocationOffsetX",
		offsetYKey = "squareMinimapStatsLocationOffsetY",
		fontSizeKey = "squareMinimapStatsLocationFontSize",
		colorKey = "squareMinimapStatsLocationColor",
		useClassColorKey = "squareMinimapStatsLocationUseClassColor",
		anchorPoint = "TOP",
	},
	coordinates = {
		enabledKey = "squareMinimapStatsCoordinates",
		anchorKey = "squareMinimapStatsCoordinatesAnchor",
		offsetXKey = "squareMinimapStatsCoordinatesOffsetX",
		offsetYKey = "squareMinimapStatsCoordinatesOffsetY",
		fontSizeKey = "squareMinimapStatsCoordinatesFontSize",
		colorKey = "squareMinimapStatsCoordinatesColor",
		useClassColorKey = "squareMinimapStatsCoordinatesUseClassColor",
		anchorPoint = "TOP",
	},
}

local squareMinimapStatsOrder = { "time", "fps", "latency", "location", "coordinates" }

local function ensureSquareMinimapStatsDefaults()
	if not addon.db then return end
	for key, value in pairs(squareMinimapStatsDefaults) do
		if addon.db[key] == nil then addon.db[key] = copyDefaultValue(value) end
	end
	addon.db.squareMinimapStatsFont = normalizeSquareMinimapStatsFontSelection(addon.db.squareMinimapStatsFont, nil)
	addon.db.squareMinimapStatsOutline = normalizeSquareMinimapStatsOutlineSelection(addon.db.squareMinimapStatsOutline, nil)
	addon.db.squareMinimapStatsTimeLeftClickAction =
		normalizeSquareMinimapTimeLeftClickAction(addon.db.squareMinimapStatsTimeLeftClickAction, squareMinimapStatsDefaults.squareMinimapStatsTimeLeftClickAction)
	addon.db.squareMinimapStatsTimeAnchor = normalizeSquareMinimapAnchorSelection(addon.db.squareMinimapStatsTimeAnchor, nil, squareMinimapStatsDefaults.squareMinimapStatsTimeAnchor)
	addon.db.squareMinimapStatsFPSAnchor = normalizeSquareMinimapAnchorSelection(addon.db.squareMinimapStatsFPSAnchor, nil, squareMinimapStatsDefaults.squareMinimapStatsFPSAnchor)
	addon.db.squareMinimapStatsLatencyAnchor = normalizeSquareMinimapAnchorSelection(addon.db.squareMinimapStatsLatencyAnchor, nil, squareMinimapStatsDefaults.squareMinimapStatsLatencyAnchor)
	addon.db.squareMinimapStatsLocationAnchor = normalizeSquareMinimapAnchorSelection(addon.db.squareMinimapStatsLocationAnchor, nil, squareMinimapStatsDefaults.squareMinimapStatsLocationAnchor)
	addon.db.squareMinimapStatsCoordinatesAnchor =
		normalizeSquareMinimapAnchorSelection(addon.db.squareMinimapStatsCoordinatesAnchor, nil, squareMinimapStatsDefaults.squareMinimapStatsCoordinatesAnchor)
	addon.db.squareMinimapStatsTrackingButtonAnchor =
		normalizeSquareMinimapAnchorSelection(addon.db.squareMinimapStatsTrackingButtonAnchor, nil, squareMinimapStatsDefaults.squareMinimapStatsTrackingButtonAnchor)
end

local function getSquareMinimapStatsState()
	addon.variables = addon.variables or {}
	addon.variables.squareMinimapStats = addon.variables.squareMinimapStats or {
		frames = {},
		elapsed = {},
		renderConfig = {},
	}
	return addon.variables.squareMinimapStats
end

local function clamp(value, minimum, maximum)
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function shouldShowSquareMinimapStats() return addon.db and addon.db.enableSquareMinimap and addon.db.enableSquareMinimapStats end

local function shouldShowSquareMinimapTrackingButton() return shouldShowSquareMinimapStats() and addon.db and addon.db.squareMinimapStatsTrackingButton == true end

local function isInGameTrackingDisabled() return C_GameRules and C_GameRules.IsGameRuleActive and Enum and Enum.GameRule and C_GameRules.IsGameRuleActive(Enum.GameRule.IngameTrackingDisabled) end

local function getSquareMinimapTrackingButtonState()
	addon.variables = addon.variables or {}
	addon.variables.squareMinimapTrackingButton = addon.variables.squareMinimapTrackingButton or {}
	return addon.variables.squareMinimapTrackingButton
end

local function getBlizzardTrackingButton() return MinimapCluster and MinimapCluster.Tracking and MinimapCluster.Tracking.Button or nil end

local function rememberSquareMinimapTrackingButtonOrigin(button)
	local state = getSquareMinimapTrackingButtonState()
	if state.originalParent then return end
	state.originalParent = button and button:GetParent() or nil
	state.originalPoint = button and { button:GetPoint(1) } or nil
	state.originalWidth = button and button:GetWidth() or nil
	state.originalHeight = button and button:GetHeight() or nil
	state.originalFrameLevel = button and button:GetFrameLevel() or nil
	state.button = button
end

local function ensureSquareMinimapTrackingButtonHolder()
	local state = getSquareMinimapTrackingButtonState()
	if state.holder then return state.holder end
	if not Minimap then return nil end

	local holder = CreateFrame("Frame", addonName .. "SquareMinimapTrackingButtonHolder", Minimap)
	holder:SetSize(17, 17)
	holder:SetFrameStrata("HIGH")
	holder:SetFrameLevel((Minimap:GetFrameLevel() or 2) + 20)

	holder.Background = holder:CreateTexture(nil, "BACKGROUND")
	holder.Background:SetAllPoints()
	holder.Background:SetAtlas("ui-hud-minimap-button")

	holder:Hide()
	state.holder = holder
	return holder
end

local function restoreSquareMinimapTrackingButton()
	local state = getSquareMinimapTrackingButtonState()
	local button = state.button or getBlizzardTrackingButton()
	if not button then return end

	local originalParent = state.originalParent
	if originalParent and button:GetParent() ~= originalParent then button:SetParent(originalParent) end

	button:ClearAllPoints()
	local point = state.originalPoint
	if point and point[1] then
		local relativeTo = point[2] or originalParent
		local relativePoint = point[3] or point[1]
		button:SetPoint(point[1], relativeTo, relativePoint, point[4] or 0, point[5] or 0)
	elseif originalParent then
		button:SetPoint("CENTER", originalParent, "CENTER", 0, 0)
	end

	if state.originalWidth and state.originalHeight then button:SetSize(state.originalWidth, state.originalHeight) end
	if state.originalFrameLevel and button.SetFrameLevel then button:SetFrameLevel(state.originalFrameLevel) end
	if state.holder then state.holder:Hide() end
	state.isCustomized = false
end

function addon.functions.applySquareMinimapTrackingButton()
	if not MinimapCluster or not MinimapCluster.Tracking then return end

	local state = getSquareMinimapTrackingButtonState()
	local trackingFrame = MinimapCluster.Tracking
	local button = getBlizzardTrackingButton()
	if not button then return end

	local showCustomButton = shouldShowSquareMinimapTrackingButton() and not isInGameTrackingDisabled()

	if not showCustomButton then
		if state.isCustomized then
			restoreSquareMinimapTrackingButton()
			if not isInGameTrackingDisabled() then trackingFrame:Show() end
		end
		return
	end

	local holder = ensureSquareMinimapTrackingButtonHolder()
	if not holder then return end

	rememberSquareMinimapTrackingButtonOrigin(button)

	local point = normalizeSquareMinimapAnchorSelection(addon.db and addon.db.squareMinimapStatsTrackingButtonAnchor, nil, squareMinimapStatsDefaults.squareMinimapStatsTrackingButtonAnchor)
	local x = tonumber(addon.db and addon.db.squareMinimapStatsTrackingButtonOffsetX) or squareMinimapStatsDefaults.squareMinimapStatsTrackingButtonOffsetX or 0
	local y = tonumber(addon.db and addon.db.squareMinimapStatsTrackingButtonOffsetY) or squareMinimapStatsDefaults.squareMinimapStatsTrackingButtonOffsetY or 0
	local scale = clamp(tonumber(addon.db and addon.db.squareMinimapStatsTrackingButtonScale) or squareMinimapStatsDefaults.squareMinimapStatsTrackingButtonScale or 1, 0.5, 2.0)
	local showBackground = not addon.db or addon.db.squareMinimapStatsTrackingButtonShowBackground ~= false

	if holder:GetParent() ~= Minimap then holder:SetParent(Minimap) end
	holder:SetFrameLevel((Minimap:GetFrameLevel() or 2) + 20)
	holder:ClearAllPoints()
	holder:SetPoint(point, Minimap, point, x, y)
	holder:SetScale(scale)
	holder.Background:SetShown(showBackground)

	if button:GetParent() ~= holder then button:SetParent(holder) end
	button:ClearAllPoints()
	button:SetPoint("CENTER", holder, "CENTER", 0, 0)
	if button.SetFrameLevel then button:SetFrameLevel((holder:GetFrameLevel() or 2) + 1) end

	holder:Show()
	trackingFrame:Hide()
	state.isCustomized = true
end

local function getSquareMinimapStatsColor(colorKey)
	local fallback = squareMinimapStatsDefaults[colorKey] or { r = 1, g = 1, b = 1, a = 1 }
	local color = addon.db and addon.db[colorKey]
	if type(color) ~= "table" then color = fallback end
	return clamp(tonumber(color.r) or fallback.r or 1, 0, 1),
		clamp(tonumber(color.g) or fallback.g or 1, 0, 1),
		clamp(tonumber(color.b) or fallback.b or 1, 0, 1),
		clamp(tonumber(color.a) or fallback.a or 1, 0, 1)
end

local function getSquareMinimapPlayerClassColor()
	local classToken = (addon.variables and addon.variables.unitClass) or (UnitClass and select(2, UnitClass("player"))) or nil
	local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	local classColor = colors and classToken and colors[classToken] or nil
	if not classColor then return 1, 1, 1 end
	return clamp(tonumber(classColor.r) or 1, 0, 1), clamp(tonumber(classColor.g) or 1, 0, 1), clamp(tonumber(classColor.b) or 1, 0, 1)
end

local function getSquareMinimapStatsFontPath()
	local fallback = (addon.functions and addon.functions.GetGlobalDefaultFontFace and addon.functions.GetGlobalDefaultFontFace())
		or (addon.variables and addon.variables.defaultFont)
		or STANDARD_TEXT_FONT
	if addon.functions and addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(addon.db and addon.db.squareMinimapStatsFont, fallback) or fallback end
	local font = addon.db and addon.db.squareMinimapStatsFont
	if type(font) ~= "string" or font == "" then font = fallback end
	return font
end

local function getSquareMinimapStatsOutlineFlag()
	local outline = normalizeSquareMinimapStatsOutlineSelection(addon.db and addon.db.squareMinimapStatsOutline, nil)
	if addon.functions and addon.functions.GetFontFlagsForStyle then
		return addon.functions.GetFontFlagsForStyle(outline, "OUTLINE")
	end
	if outline == nil or outline == "" or outline == "NONE" then return nil end
	return outline
end

local function colorizeSquareMinimapText(text, r, g, b)
	local rr = math.floor(clamp(r or 1, 0, 1) * 255 + 0.5)
	local gg = math.floor(clamp(g or 1, 0, 1) * 255 + 0.5)
	local bb = math.floor(clamp(b or 1, 0, 1) * 255 + 0.5)
	return ("|cff%02x%02x%02x%s|r"):format(rr, gg, bb, tostring(text or ""))
end

local function getSquareMinimapFPSColor(value)
	local medium = math.floor((tonumber(addon.db and addon.db.squareMinimapStatsFPSThresholdMedium) or 30) + 0.5)
	local high = math.floor((tonumber(addon.db and addon.db.squareMinimapStatsFPSThresholdHigh) or 60) + 0.5)
	if medium < 1 then medium = 1 end
	if high < medium then high = medium end
	if value >= high then return getSquareMinimapStatsColor("squareMinimapStatsFPSColorHigh") end
	if value >= medium then return getSquareMinimapStatsColor("squareMinimapStatsFPSColorMid") end
	return getSquareMinimapStatsColor("squareMinimapStatsFPSColorLow")
end

local function getSquareMinimapLatencyColor(value)
	local low = math.floor((tonumber(addon.db and addon.db.squareMinimapStatsLatencyThresholdLow) or 50) + 0.5)
	local medium = math.floor((tonumber(addon.db and addon.db.squareMinimapStatsLatencyThresholdMid) or 150) + 0.5)
	if low < 0 then low = 0 end
	if medium < low then medium = low end
	if value <= low then return getSquareMinimapStatsColor("squareMinimapStatsLatencyColorLow") end
	if value <= medium then return getSquareMinimapStatsColor("squareMinimapStatsLatencyColorMid") end
	return getSquareMinimapStatsColor("squareMinimapStatsLatencyColorHigh")
end

local function getSquareMinimapStatsZoneColor()
	local zoneType = C_PvP and C_PvP.GetZonePVPInfo and C_PvP.GetZonePVPInfo() or nil
	if zoneType == "sanctuary" then return 0.41, 0.80, 0.94 end
	if zoneType == "arena" then return 1.00, 0.10, 0.10 end
	if zoneType == "friendly" then return 0.10, 1.00, 0.10 end
	if zoneType == "hostile" then return 1.00, 0.10, 0.10 end
	if zoneType == "contested" then return 1.00, 0.70, 0.00 end
	return (NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.r) or 1, (NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.g) or 0.82, (NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.b) or 0
end

local function getSquareMinimapStatJustify(point)
	if point == "TOP" or point == "BOTTOM" or point == "CENTER" then return "CENTER" end
	if point and point:find("RIGHT", 1, true) then return "RIGHT" end
	if point and point:find("LEFT", 1, true) then return "LEFT" end
	return "CENTER"
end

local function normalizeSquareMinimapAnchor(anchor, fallback)
	if type(anchor) == "string" and squareMinimapStatsAnchorOptions[anchor] then return anchor end
	if type(fallback) == "string" and squareMinimapStatsAnchorOptions[fallback] then return fallback end
	return "CENTER"
end

local function getSquareMinimapFontStringWidth(fontString)
	if not fontString then return 0 end
	local width = fontString.GetUnboundedStringWidth and fontString:GetUnboundedStringWidth() or nil
	if not width or width <= 0 then width = fontString:GetStringWidth() or 0 end
	return width
end

local squareMinimapCoordinateFormatCache = {}

local function getSquareMinimapCoordinateFormat(decimals)
	local fmt = squareMinimapCoordinateFormatCache[decimals]
	if fmt then return fmt end
	fmt = ("%%.%df, %%.%df"):format(decimals, decimals)
	squareMinimapCoordinateFormatCache[decimals] = fmt
	return fmt
end

local function roundScaledValue(value, scale)
	local scaled = (tonumber(value) or 0) * scale
	if scaled >= 0 then return math.floor(scaled + 0.5) end
	return math.ceil(scaled - 0.5)
end

local function clearSquareMinimapCoordinateCache(frame)
	if not frame then return end
	frame._eqolCoordinatesMapID = nil
	frame._eqolCoordinatesDecimals = nil
	frame._eqolCoordinatesX = nil
	frame._eqolCoordinatesY = nil
end

local function utf8Iter(str) return (str or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") end

local function utf8Len(str)
	local len = 0
	for _ in utf8Iter(str) do
		len = len + 1
	end
	return len
end

local function utf8Sub(str, i, j)
	str = str or ""
	if str == "" then return "" end
	i = i or 1
	j = j or -1
	if i < 1 then i = 1 end
	local len = utf8Len(str)
	if j < 0 then j = len + j + 1 end
	if j > len then j = len end
	if i > j then return "" end
	local pos = 1
	local startByte, endByte
	local idx = 0
	for char in utf8Iter(str) do
		idx = idx + 1
		if idx == i then startByte = pos end
		if idx == j then
			endByte = pos + #char - 1
			break
		end
		pos = pos + #char
	end
	return str:sub(startByte or 1, endByte or #str)
end

local function getSquareMinimapLocationMaxWidth(point, xOffset)
	if not Minimap or not Minimap.GetWidth then return nil end
	local minimapWidth = tonumber(Minimap:GetWidth()) or 0
	if minimapWidth <= 0 then return nil end

	local margin = 8
	local anchorX
	if point and point:find("LEFT", 1, true) then
		anchorX = 0
	elseif point and point:find("RIGHT", 1, true) then
		anchorX = minimapWidth
	else
		anchorX = minimapWidth * 0.5
	end

	anchorX = anchorX + (tonumber(xOffset) or 0)
	local leftSpace = anchorX - margin
	local rightSpace = (minimapWidth - margin) - anchorX
	local justify = getSquareMinimapStatJustify(point)
	local maxWidth
	if justify == "LEFT" then
		maxWidth = rightSpace
	elseif justify == "RIGHT" then
		maxWidth = leftSpace
	else
		maxWidth = math.min(leftSpace, rightSpace) * 2
	end

	local upperBound = math.max(minimapWidth - (margin * 2), 24)
	return clamp(maxWidth or 0, 24, upperBound)
end

local function truncateSquareMinimapTextToWidth(fontString, text, maxWidth)
	if not fontString then return text or "" end
	local source = tostring(text or "")
	if source == "" or not maxWidth or maxWidth <= 0 then return source end

	fontString:SetText(source)
	if getSquareMinimapFontStringWidth(fontString) <= maxWidth then return source end

	local ellipsis = "..."
	fontString:SetText(ellipsis)
	if getSquareMinimapFontStringWidth(fontString) > maxWidth then return "" end

	local low, high = 0, utf8Len(source)
	local best = ellipsis
	while low <= high do
		local mid = math.floor((low + high) / 2)
		local prefix = utf8Sub(source, 1, mid):gsub("%s+$", "")
		local candidate = (prefix ~= "" and (prefix .. ellipsis)) or ellipsis
		fontString:SetText(candidate)
		if getSquareMinimapFontStringWidth(fontString) <= maxWidth then
			best = candidate
			low = mid + 1
		else
			high = mid - 1
		end
	end
	return best
end

local handleSquareMinimapTimeClick
local configureSquareMinimapStatFrameInteraction

local function ensureSquareMinimapStatFrame(statKey)
	local state = getSquareMinimapStatsState()
	local existing = state.frames[statKey]
	if existing and existing.text then
		if not existing.textSecondary then
			existing.textSecondary = existing:CreateFontString(nil, "OVERLAY")
			existing.textSecondary:SetWordWrap(false)
			existing.textSecondary:SetJustifyV("MIDDLE")
			existing.textSecondary:Hide()
		end
		configureSquareMinimapStatFrameInteraction(existing, statKey)
		return existing
	end
	if not Minimap then return nil end

	local frame = CreateFrame("Frame", addonName .. "SquareMinimapStat_" .. statKey, Minimap)
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel((Minimap:GetFrameLevel() or 2) + 20)
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetWordWrap(false)
	frame.text:SetJustifyV("MIDDLE")
	frame.textSecondary = frame:CreateFontString(nil, "OVERLAY")
	frame.textSecondary:SetWordWrap(false)
	frame.textSecondary:SetJustifyV("MIDDLE")
	frame.textSecondary:Hide()
	configureSquareMinimapStatFrameInteraction(frame, statKey)
	frame:Hide()
	state.frames[statKey] = frame
	return frame
end

local function hideSquareMinimapStats()
	local state = getSquareMinimapStatsState()
	for _, frame in pairs(state.frames) do
		if frame then frame:Hide() end
	end
end

local function formatSquareMinimapClock(hours, minutes, seconds, use24Hour, showSeconds)
	if hours == nil or minutes == nil then return "" end
	local h = hours
	local m = minutes
	local s = seconds or 0
	local suffix = ""
	if not use24Hour then
		local isPM = h >= 12
		suffix = isPM and (TIMEMANAGER_PM or "PM") or (TIMEMANAGER_AM or "AM")
		h = h % 12
		if h == 0 then h = 12 end
	end
	if showSeconds then
		if use24Hour then return ("%02d:%02d:%02d"):format(h, m, s) end
		return ("%d:%02d:%02d %s"):format(h, m, s, suffix)
	end
	if use24Hour then return ("%02d:%02d"):format(h, m) end
	return ("%d:%02d %s"):format(h, m, suffix)
end

local function getSquareMinimapTimeText()
	local localParts = date("*t")
	local localHour = localParts and localParts.hour or nil
	local localMinute = localParts and localParts.min or nil
	local localSecond = localParts and localParts.sec or 0

	local serverHour, serverMinute = nil, nil
	if GetGameTime then
		serverHour, serverMinute = GetGameTime()
	end

	local use24Hour = addon.db.squareMinimapStatsTimeUse24Hour ~= false
	local showSeconds = addon.db.squareMinimapStatsTimeShowSeconds == true
	local mode = addon.db.squareMinimapStatsTimeDisplayMode or "server"

	local localText = formatSquareMinimapClock(localHour, localMinute, localSecond, use24Hour, showSeconds)
	local serverText = formatSquareMinimapClock(serverHour, serverMinute, localSecond, use24Hour, showSeconds)

	if mode == "localTime" then return localText end
	if mode == "both" then
		if serverText == "" then return localText end
		if localText == "" then return serverText end
		return ("%s / %s"):format(serverText, localText)
	end
	if serverText == "" then return localText end
	return serverText
end

local function getSquareMinimapTimeLeftClickAction()
	return normalizeSquareMinimapTimeLeftClickAction(addon.db and addon.db.squareMinimapStatsTimeLeftClickAction, squareMinimapStatsDefaults.squareMinimapStatsTimeLeftClickAction)
end

handleSquareMinimapTimeClick = function(button)
	if button ~= "LeftButton" then return end
	if getSquareMinimapTimeLeftClickAction() == "calendar" then
		if ToggleCalendar then
			ToggleCalendar()
		elseif ToggleTimeManager then
			ToggleTimeManager()
		end
	elseif ToggleTimeManager then
		ToggleTimeManager()
	end
end

configureSquareMinimapStatFrameInteraction = function(frame, statKey)
	if not frame then return end
	if statKey == "time" then
		frame:EnableMouse(true)
		frame:SetHitRectInsets(-4, -4, -2, -2)
		frame:SetScript("OnEnter", nil)
		frame:SetScript("OnLeave", nil)
		frame:SetScript("OnMouseUp", function(_, button) handleSquareMinimapTimeClick(button) end)
	else
		frame:EnableMouse(false)
		frame:SetHitRectInsets(0, 0, 0, 0)
		frame:SetScript("OnEnter", nil)
		frame:SetScript("OnLeave", nil)
		frame:SetScript("OnMouseUp", nil)
	end
end

local getSquareMinimapLocationLines

local function getSquareMinimapLocationText()
	local showZone = addon.db.squareMinimapStatsLocationShowZone ~= false
	local showSubzone = addon.db.squareMinimapStatsLocationShowSubzone ~= false
	local splitLines = addon.db.squareMinimapStatsLocationSubzoneBelowZone == true
	local primaryText, secondaryText = getSquareMinimapLocationLines(showZone, showSubzone, splitLines)
	if secondaryText ~= "" then return ("%s\n%s"):format(primaryText, secondaryText) end
	return primaryText
end

local function getSquareMinimapCoordinatesText(frame, renderCfg)
	if renderCfg and renderCfg.hideInInstance and IsInInstance and IsInInstance() then
		clearSquareMinimapCoordinateCache(frame)
		return ""
	end
	if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return "" end
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		clearSquareMinimapCoordinateCache(frame)
		return ""
	end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then
		clearSquareMinimapCoordinateCache(frame)
		return ""
	end
	local decimals = (renderCfg and renderCfg.decimals) or 2
	local scale = 10 ^ decimals
	local x = roundScaledValue((pos.x or 0) * 100, scale)
	local y = roundScaledValue((pos.y or 0) * 100, scale)
	if frame and frame._eqolCoordinatesMapID == mapID and frame._eqolCoordinatesDecimals == decimals and frame._eqolCoordinatesX == x and frame._eqolCoordinatesY == y then
		return frame._eqolPrimaryText or ""
	end
	local text = string.format(getSquareMinimapCoordinateFormat(decimals), x / scale, y / scale)
	if frame then
		frame._eqolCoordinatesMapID = mapID
		frame._eqolCoordinatesDecimals = decimals
		frame._eqolCoordinatesX = x
		frame._eqolCoordinatesY = y
	end
	return text
end

local function getSquareMinimapLatencySplitTexts()
	local _, _, home, world = GetNetStats()
	home = math.floor((home or 0) + 0.5)
	world = math.floor((world or 0) + 0.5)
	local hr, hg, hb = getSquareMinimapLatencyColor(home)
	local wr, wg, wb = getSquareMinimapLatencyColor(world)
	local homeText = ("H %sms"):format(colorizeSquareMinimapText(home, hr, hg, hb))
	local worldText = ("W %sms"):format(colorizeSquareMinimapText(world, wr, wg, wb))
	return homeText, worldText, home, world
end

local function getSquareMinimapLatencyText()
	local mode = addon.db.squareMinimapStatsLatencyMode or "max"
	local homeText, worldText, home, world = getSquareMinimapLatencySplitTexts()
	if mode == "home" then return homeText end
	if mode == "world" then return worldText end
	if mode == "split" then return ("%s / %s"):format(homeText, worldText) end
	if mode == "split_vertical" then return ("%s\n%s"):format(homeText, worldText) end
	local maxValue = math.max(home, world)
	local mr, mg, mb = getSquareMinimapLatencyColor(maxValue)
	return ("MS %s"):format(colorizeSquareMinimapText(maxValue, mr, mg, mb))
end

local function getSquareMinimapStatText(statKey)
	if statKey == "time" then return getSquareMinimapTimeText() end
	if statKey == "fps" then
		local fps = math.floor((GetFramerate() or 0) + 0.5)
		local fr, fg, fb = getSquareMinimapFPSColor(fps)
		return ("FPS %s"):format(colorizeSquareMinimapText(fps, fr, fg, fb))
	end
	if statKey == "latency" then return getSquareMinimapLatencyText() end
	if statKey == "location" then return getSquareMinimapLocationText() end
	if statKey == "coordinates" then
		return getSquareMinimapCoordinatesText(nil, {
			decimals = math.floor(clamp(tonumber(addon.db and addon.db.squareMinimapStatsCoordinatesDecimals) or 2, 0, 3) + 0.5),
			hideInInstance = addon.db and addon.db.squareMinimapStatsCoordinatesHideInInstance == true,
		})
	end
	return ""
end

local function buildSquareMinimapTimeText(frame, renderCfg)
	local localParts = date("*t")
	local localHour = localParts and localParts.hour or nil
	local localMinute = localParts and localParts.min or nil
	local localSecond = localParts and localParts.sec or 0
	local serverHour, serverMinute = nil, nil
	if GetGameTime then
		serverHour, serverMinute = GetGameTime()
	end

	local mode = renderCfg and renderCfg.timeDisplayMode or "server"
	local use24Hour = renderCfg and renderCfg.timeUse24Hour ~= false
	local showSeconds = renderCfg and renderCfg.timeShowSeconds == true

	if
		frame
		and frame._eqolTimeMode == mode
		and frame._eqolTimeUse24Hour == use24Hour
		and frame._eqolTimeShowSeconds == showSeconds
		and frame._eqolTimeLocalHour == localHour
		and frame._eqolTimeLocalMinute == localMinute
		and frame._eqolTimeLocalSecond == localSecond
		and frame._eqolTimeServerHour == serverHour
		and frame._eqolTimeServerMinute == serverMinute
	then
		return frame._eqolPrimaryText or ""
	end

	local localText = formatSquareMinimapClock(localHour, localMinute, localSecond, use24Hour, showSeconds)
	local serverText = formatSquareMinimapClock(serverHour, serverMinute, localSecond, use24Hour, showSeconds)
	local text
	if mode == "localTime" then
		text = localText
	elseif mode == "both" then
		if serverText == "" then
			text = localText
		elseif localText == "" then
			text = serverText
		else
			text = ("%s / %s"):format(serverText, localText)
		end
	else
		text = serverText ~= "" and serverText or localText
	end

	if frame then
		frame._eqolTimeMode = mode
		frame._eqolTimeUse24Hour = use24Hour
		frame._eqolTimeShowSeconds = showSeconds
		frame._eqolTimeLocalHour = localHour
		frame._eqolTimeLocalMinute = localMinute
		frame._eqolTimeLocalSecond = localSecond
		frame._eqolTimeServerHour = serverHour
		frame._eqolTimeServerMinute = serverMinute
	end
	return text
end

getSquareMinimapLocationLines = function(showZone, showSubzone, splitLines)
	local zone = GetZoneText and GetZoneText() or nil
	if not zone or zone == "" then zone = GetRealZoneText and GetRealZoneText() or "" end
	local subzone = GetSubZoneText and GetSubZoneText() or ""
	if not showZone and not showSubzone then return "", "" end

	if showZone and showSubzone then
		if subzone ~= "" and subzone ~= zone then
			if zone and zone ~= "" then
				if splitLines then return zone, subzone end
				return zone .. " - " .. subzone, ""
			end
			return subzone, ""
		end
		if zone and zone ~= "" then return zone, "" end
		return subzone, ""
	end

	if showZone then
		if zone and zone ~= "" then return zone, "" end
		return subzone, ""
	end

	if subzone ~= "" then return subzone, "" end
	if zone and zone ~= "" then return zone, "" end
	return "", ""
end

local function buildSquareMinimapLocationTexts(renderCfg)
	local showZone = renderCfg and renderCfg.locationShowZone ~= false
	local showSubzone = renderCfg and renderCfg.locationShowSubzone ~= false
	local splitLines = renderCfg and renderCfg.locationSubzoneBelowZone == true
	return getSquareMinimapLocationLines(showZone, showSubzone, splitLines)
end

local function getSquareMinimapFPSBucket(renderCfg, value)
	local medium = renderCfg and renderCfg.fpsThresholdMedium or 30
	local high = renderCfg and renderCfg.fpsThresholdHigh or 60
	if value >= high then return "high" end
	if value >= medium then return "mid" end
	return "low"
end

local function getSquareMinimapFPSBucketColor(renderCfg, bucket)
	if bucket == "high" then return renderCfg.fpsColorHighR, renderCfg.fpsColorHighG, renderCfg.fpsColorHighB end
	if bucket == "mid" then return renderCfg.fpsColorMidR, renderCfg.fpsColorMidG, renderCfg.fpsColorMidB end
	return renderCfg.fpsColorLowR, renderCfg.fpsColorLowG, renderCfg.fpsColorLowB
end

local function buildSquareMinimapFPSText(frame, renderCfg)
	local fps = math.floor((GetFramerate() or 0) + 0.5)
	local bucket = getSquareMinimapFPSBucket(renderCfg, fps)
	local r, g, b = getSquareMinimapFPSBucketColor(renderCfg, bucket)
	if frame and frame._eqolFPSValue == fps and frame._eqolFPSBucket == bucket and frame._eqolFPSColorR == r and frame._eqolFPSColorG == g and frame._eqolFPSColorB == b then
		return frame._eqolPrimaryText or ""
	end
	local text = ("FPS %s"):format(colorizeSquareMinimapText(fps, r, g, b))
	if frame then
		frame._eqolFPSValue = fps
		frame._eqolFPSBucket = bucket
		frame._eqolFPSColorR = r
		frame._eqolFPSColorG = g
		frame._eqolFPSColorB = b
	end
	return text
end

local function getSquareMinimapLatencyBucket(renderCfg, value)
	local low = renderCfg and renderCfg.latencyThresholdLow or 50
	local mid = renderCfg and renderCfg.latencyThresholdMid or 150
	if value <= low then return "low" end
	if value <= mid then return "mid" end
	return "high"
end

local function getSquareMinimapLatencyBucketColor(renderCfg, bucket)
	if bucket == "low" then return renderCfg.latencyColorLowR, renderCfg.latencyColorLowG, renderCfg.latencyColorLowB end
	if bucket == "mid" then return renderCfg.latencyColorMidR, renderCfg.latencyColorMidG, renderCfg.latencyColorMidB end
	return renderCfg.latencyColorHighR, renderCfg.latencyColorHighG, renderCfg.latencyColorHighB
end

local function buildSquareMinimapLatencyTexts(frame, renderCfg)
	local _, _, home, world = GetNetStats()
	home = math.floor((home or 0) + 0.5)
	world = math.floor((world or 0) + 0.5)
	local mode = renderCfg and renderCfg.latencyMode or "max"
	local homeBucket = getSquareMinimapLatencyBucket(renderCfg, home)
	local worldBucket = getSquareMinimapLatencyBucket(renderCfg, world)
	local maxValue = math.max(home, world)
	local maxBucket = getSquareMinimapLatencyBucket(renderCfg, maxValue)
	local hr, hg, hb = getSquareMinimapLatencyBucketColor(renderCfg, homeBucket)
	local wr, wg, wb = getSquareMinimapLatencyBucketColor(renderCfg, worldBucket)
	local mr, mg, mb = getSquareMinimapLatencyBucketColor(renderCfg, maxBucket)

	if
		frame
		and frame._eqolLatencyMode == mode
		and frame._eqolLatencyHome == home
		and frame._eqolLatencyWorld == world
		and frame._eqolLatencyHomeBucket == homeBucket
		and frame._eqolLatencyWorldBucket == worldBucket
		and frame._eqolLatencyMaxBucket == maxBucket
		and frame._eqolLatencyHomeColorR == hr
		and frame._eqolLatencyHomeColorG == hg
		and frame._eqolLatencyHomeColorB == hb
		and frame._eqolLatencyWorldColorR == wr
		and frame._eqolLatencyWorldColorG == wg
		and frame._eqolLatencyWorldColorB == wb
		and frame._eqolLatencyMaxColorR == mr
		and frame._eqolLatencyMaxColorG == mg
		and frame._eqolLatencyMaxColorB == mb
	then
		return frame._eqolPrimaryText or "", frame._eqolSecondaryText or ""
	end

	local homeText = ("H %sms"):format(colorizeSquareMinimapText(home, hr, hg, hb))
	local worldText = ("W %sms"):format(colorizeSquareMinimapText(world, wr, wg, wb))
	local primaryText, secondaryText = "", ""
	if mode == "home" then
		primaryText = homeText
	elseif mode == "world" then
		primaryText = worldText
	elseif mode == "split" or mode == "split_vertical" then
		primaryText = homeText
		secondaryText = worldText
	else
		primaryText = ("MS %s"):format(colorizeSquareMinimapText(maxValue, mr, mg, mb))
	end

	if frame then
		frame._eqolLatencyMode = mode
		frame._eqolLatencyHome = home
		frame._eqolLatencyWorld = world
		frame._eqolLatencyHomeBucket = homeBucket
		frame._eqolLatencyWorldBucket = worldBucket
		frame._eqolLatencyMaxBucket = maxBucket
		frame._eqolLatencyHomeColorR = hr
		frame._eqolLatencyHomeColorG = hg
		frame._eqolLatencyHomeColorB = hb
		frame._eqolLatencyWorldColorR = wr
		frame._eqolLatencyWorldColorG = wg
		frame._eqolLatencyWorldColorB = wb
		frame._eqolLatencyMaxColorR = mr
		frame._eqolLatencyMaxColorG = mg
		frame._eqolLatencyMaxColorB = mb
	end
	return primaryText, secondaryText
end

local function getSquareMinimapStatRenderConfig(statKey)
	local state = getSquareMinimapStatsState()
	state.renderConfig = state.renderConfig or {}
	local cached = state.renderConfig[statKey]
	local globalFontStateVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	if cached and cached.globalFontStateVersion == globalFontStateVersion then return cached end

	local cfg = squareMinimapStatsConfig[statKey]
	if not (cfg and addon.db) then return nil end

	local point = normalizeSquareMinimapAnchor(addon.db[cfg.anchorKey], cfg.anchorPoint)
	local x = tonumber(addon.db[cfg.offsetXKey]) or squareMinimapStatsDefaults[cfg.offsetXKey] or 0
	local y = tonumber(addon.db[cfg.offsetYKey]) or squareMinimapStatsDefaults[cfg.offsetYKey] or 0
	local size = clamp(tonumber(addon.db[cfg.fontSizeKey]) or squareMinimapStatsDefaults[cfg.fontSizeKey] or 12, 8, 32)
	local latencyMode = statKey == "latency" and (addon.db.squareMinimapStatsLatencyMode or "max") or nil
	local useVerticalLatency = statKey == "latency" and latencyMode == "split_vertical"
	local lineGap = math.max(math.floor(size * 0.15), 2)
	local justify = getSquareMinimapStatJustify(point)
	local fontPath = getSquareMinimapStatsFontPath()
	local outline = getSquareMinimapStatsOutlineFlag()
	local r, g, b, a = getSquareMinimapStatsColor(cfg.colorKey)

	cached = {
		globalFontStateVersion = globalFontStateVersion,
		point = point,
		x = x,
		y = y,
		size = size,
		latencyMode = latencyMode,
		useVerticalLatency = useVerticalLatency,
		lineGap = lineGap,
		justify = justify,
		fontPath = fontPath,
		outline = outline,
		r = r,
		g = g,
		b = b,
		a = a,
		useClassColor = cfg.useClassColorKey and addon.db[cfg.useClassColorKey] == true or false,
	}
	if statKey == "time" then
		cached.timeDisplayMode = addon.db.squareMinimapStatsTimeDisplayMode or "server"
		cached.timeUse24Hour = addon.db.squareMinimapStatsTimeUse24Hour ~= false
		cached.timeShowSeconds = addon.db.squareMinimapStatsTimeShowSeconds == true
	elseif statKey == "fps" then
		cached.fpsThresholdMedium = math.max(1, math.floor((tonumber(addon.db.squareMinimapStatsFPSThresholdMedium) or 30) + 0.5))
		cached.fpsThresholdHigh = math.max(cached.fpsThresholdMedium, math.floor((tonumber(addon.db.squareMinimapStatsFPSThresholdHigh) or 60) + 0.5))
	elseif statKey == "latency" then
		cached.latencyThresholdLow = math.max(0, math.floor((tonumber(addon.db.squareMinimapStatsLatencyThresholdLow) or 50) + 0.5))
		cached.latencyThresholdMid = math.max(cached.latencyThresholdLow, math.floor((tonumber(addon.db.squareMinimapStatsLatencyThresholdMid) or 150) + 0.5))
	elseif statKey == "location" then
		cached.useZoneColor = addon.db.squareMinimapStatsLocationUseZoneColor == true
		cached.locationShowZone = addon.db.squareMinimapStatsLocationShowZone ~= false
		cached.locationShowSubzone = addon.db.squareMinimapStatsLocationShowSubzone ~= false
		cached.locationSubzoneBelowZone = addon.db.squareMinimapStatsLocationSubzoneBelowZone == true
	elseif statKey == "coordinates" then
		cached.decimals = math.floor(clamp(tonumber(addon.db.squareMinimapStatsCoordinatesDecimals) or 2, 0, 3) + 0.5)
		cached.hideInInstance = addon.db.squareMinimapStatsCoordinatesHideInInstance == true
	end
	if statKey == "fps" then
		cached.fpsColorLowR, cached.fpsColorLowG, cached.fpsColorLowB = getSquareMinimapStatsColor("squareMinimapStatsFPSColorLow")
		cached.fpsColorMidR, cached.fpsColorMidG, cached.fpsColorMidB = getSquareMinimapStatsColor("squareMinimapStatsFPSColorMid")
		cached.fpsColorHighR, cached.fpsColorHighG, cached.fpsColorHighB = getSquareMinimapStatsColor("squareMinimapStatsFPSColorHigh")
	end
	if statKey == "latency" then
		cached.latencyColorLowR, cached.latencyColorLowG, cached.latencyColorLowB = getSquareMinimapStatsColor("squareMinimapStatsLatencyColorLow")
		cached.latencyColorMidR, cached.latencyColorMidG, cached.latencyColorMidB = getSquareMinimapStatsColor("squareMinimapStatsLatencyColorMid")
		cached.latencyColorHighR, cached.latencyColorHighG, cached.latencyColorHighB = getSquareMinimapStatsColor("squareMinimapStatsLatencyColorHigh")
	end
	state.renderConfig[statKey] = cached
	return cached
end

local function getSquareMinimapStatsInterval(statKey)
	if statKey == "time" then
		if addon.db.squareMinimapStatsTimeShowSeconds == true then return 1 end
		return 15
	end
	if statKey == "fps" then return clamp(tonumber(addon.db.squareMinimapStatsFPSUpdateInterval) or 0.25, 0.1, 2.0) end
	if statKey == "latency" then return clamp(tonumber(addon.db.squareMinimapStatsLatencyUpdateInterval) or 1.0, 0.2, 5.0) end
	if statKey == "coordinates" then return clamp(tonumber(addon.db.squareMinimapStatsCoordinatesUpdateInterval) or 0.2, 0.1, 1.0) end
	if statKey == "location" then return nil end
	return 0.5
end

local function updateSquareMinimapStat(statKey)
	local cfg = squareMinimapStatsConfig[statKey]
	if not cfg then return end
	local frame = ensureSquareMinimapStatFrame(statKey)
	if not frame then return end

	if not shouldShowSquareMinimapStats() or addon.db[cfg.enabledKey] ~= true then
		if statKey == "coordinates" then clearSquareMinimapCoordinateCache(frame) end
		frame:Hide()
		return
	end

	local renderCfg = getSquareMinimapStatRenderConfig(statKey)
	if not renderCfg then
		if statKey == "coordinates" then clearSquareMinimapCoordinateCache(frame) end
		frame:Hide()
		return
	end
	local point = renderCfg.point
	local x = renderCfg.x
	local y = renderCfg.y
	local size = renderCfg.size
	local useVerticalLatency = renderCfg.useVerticalLatency
	local lineGap = renderCfg.lineGap
	local justify = renderCfg.justify

	if frame._eqolAnchorPoint ~= point or frame._eqolAnchorX ~= x or frame._eqolAnchorY ~= y then
		frame:ClearAllPoints()
		frame:SetPoint(point, Minimap, point, x, y)
		frame._eqolAnchorPoint = point
		frame._eqolAnchorX = x
		frame._eqolAnchorY = y
	end

	local r, g, b, a = renderCfg.r, renderCfg.g, renderCfg.b, renderCfg.a
	if renderCfg.useClassColor then
		r, g, b = getSquareMinimapPlayerClassColor()
	elseif renderCfg.useZoneColor then
		r, g, b = getSquareMinimapStatsZoneColor()
		a = 1
	end

	if frame._eqolTextPoint ~= point then
		frame.text:ClearAllPoints()
		frame.text:SetPoint(point, frame, point, 0, 0)
		frame.textSecondary:ClearAllPoints()
		frame.textSecondary:SetPoint(point, frame, point, 0, 0)
		frame._eqolTextPoint = point
		frame._eqolSecondaryPoint = point
		frame._eqolSecondaryOffsetY = 0
	end
	if frame._eqolTextJustify ~= justify then
		frame.text:SetJustifyH(justify)
		frame.textSecondary:SetJustifyH(justify)
		frame._eqolTextJustify = justify
	end

	local fontPath = renderCfg.fontPath
	local outline = renderCfg.outline
	local outlineChoice = normalizeSquareMinimapStatsOutlineSelection(addon.db and addon.db.squareMinimapStatsOutline, nil)
	if frame._eqolFontPath ~= fontPath or frame._eqolFontSize ~= size or frame._eqolFontOutline ~= outline or frame._eqolFontStyleChoice ~= outlineChoice then
		local ok = frame.text:SetFont(fontPath, size, outline)
		if not ok then frame.text:SetFont((addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, outline) end
		local okSecondary = frame.textSecondary:SetFont(fontPath, size, outline)
		if not okSecondary then frame.textSecondary:SetFont((addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, outline) end
		if addon.functions and addon.functions.ApplyFontStyleShadow then
			addon.functions.ApplyFontStyleShadow(frame.text, outlineChoice, "OUTLINE")
			addon.functions.ApplyFontStyleShadow(frame.textSecondary, outlineChoice, "OUTLINE")
		end
		frame._eqolFontPath = fontPath
		frame._eqolFontSize = size
		frame._eqolFontOutline = outline
		frame._eqolFontStyleChoice = outlineChoice
	end
	if frame._eqolTextColorR ~= r or frame._eqolTextColorG ~= g or frame._eqolTextColorB ~= b or frame._eqolTextColorA ~= a then
		frame.text:SetTextColor(r, g, b, a)
		frame.textSecondary:SetTextColor(r, g, b, a)
		frame._eqolTextColorR = r
		frame._eqolTextColorG = g
		frame._eqolTextColorB = b
		frame._eqolTextColorA = a
	end

	local primaryText = ""
	local secondaryText = ""
	local showSecondary = false
	if useVerticalLatency then
		local homeText, worldText = buildSquareMinimapLatencyTexts(frame, renderCfg)
		local stackUpwards = point and point:find("BOTTOM", 1, true) ~= nil
		local secondaryY
		if stackUpwards then
			primaryText = worldText or ""
			secondaryText = homeText or ""
			secondaryY = size + lineGap
		else
			primaryText = homeText or ""
			secondaryText = worldText or ""
			secondaryY = -(size + lineGap)
		end
		if frame._eqolSecondaryPoint ~= point or frame._eqolSecondaryOffsetY ~= secondaryY then
			frame.textSecondary:ClearAllPoints()
			frame.textSecondary:SetPoint(point, frame, point, 0, secondaryY)
			frame._eqolSecondaryPoint = point
			frame._eqolSecondaryOffsetY = secondaryY
		end
		showSecondary = true
	else
		if statKey == "time" then
			primaryText = buildSquareMinimapTimeText(frame, renderCfg) or ""
		elseif statKey == "fps" then
			primaryText = buildSquareMinimapFPSText(frame, renderCfg) or ""
		elseif statKey == "latency" then
			primaryText = buildSquareMinimapLatencyTexts(frame, renderCfg) or ""
		elseif statKey == "location" then
			local topText, bottomText = buildSquareMinimapLocationTexts(renderCfg)
			local maxWidth = getSquareMinimapLocationMaxWidth(point, x)
			if maxWidth and maxWidth > 0 then
				topText = truncateSquareMinimapTextToWidth(frame.text, topText, maxWidth)
				if bottomText ~= "" then bottomText = truncateSquareMinimapTextToWidth(frame.textSecondary, bottomText, maxWidth) end
			end

			if bottomText ~= "" then
				local stackUpwards = point and point:find("BOTTOM", 1, true) ~= nil
				local secondaryY
				if stackUpwards then
					primaryText = bottomText or ""
					secondaryText = topText or ""
					secondaryY = size + lineGap
				else
					primaryText = topText or ""
					secondaryText = bottomText or ""
					secondaryY = -(size + lineGap)
				end
				if frame._eqolSecondaryPoint ~= point or frame._eqolSecondaryOffsetY ~= secondaryY then
					frame.textSecondary:ClearAllPoints()
					frame.textSecondary:SetPoint(point, frame, point, 0, secondaryY)
					frame._eqolSecondaryPoint = point
					frame._eqolSecondaryOffsetY = secondaryY
				end
				showSecondary = secondaryText ~= ""
				if primaryText == "" and secondaryText ~= "" then
					primaryText = secondaryText
					secondaryText = ""
					showSecondary = false
				end
			else
				primaryText = topText or ""
			end
		elseif statKey == "coordinates" then
			primaryText = getSquareMinimapCoordinatesText(frame, renderCfg) or ""
		else
			primaryText = getSquareMinimapStatText(statKey) or ""
		end
	end

	if frame._eqolPrimaryText ~= primaryText then
		frame.text:SetText(primaryText)
		frame._eqolPrimaryText = primaryText
	end
	if showSecondary then
		if frame._eqolSecondaryText ~= secondaryText then
			frame.textSecondary:SetText(secondaryText)
			frame._eqolSecondaryText = secondaryText
		end
		if not frame.textSecondary:IsShown() then frame.textSecondary:Show() end
	else
		if frame.textSecondary:IsShown() then frame.textSecondary:Hide() end
		if frame._eqolSecondaryText ~= "" then
			frame.textSecondary:SetText("")
			frame._eqolSecondaryText = ""
		end
	end

	if primaryText == "" and secondaryText == "" then
		frame:Hide()
		return
	end

	local width = getSquareMinimapFontStringWidth(frame.text)
	local height = frame.text:GetStringHeight()
	if frame.textSecondary:IsShown() then
		width = math.max(width, getSquareMinimapFontStringWidth(frame.textSecondary))
		height = height + frame.textSecondary:GetStringHeight() + lineGap
	end
	local finalW = math.max(width, 1)
	local finalH = math.max(height, 1)
	if frame._eqolWidth ~= finalW or frame._eqolHeight ~= finalH then
		frame:SetSize(finalW, finalH)
		frame._eqolWidth = finalW
		frame._eqolHeight = finalH
	end
	frame:Show()
end

local function stopSquareMinimapStatsTicker()
	local state = getSquareMinimapStatsState()
	if state.ticker then
		state.ticker:Cancel()
		state.ticker = nil
	end
	state.tickerInterval = nil
end

local function isSquareMinimapStatEnabled(statKey)
	local cfg = squareMinimapStatsConfig[statKey]
	return cfg and addon.db and addon.db[cfg.enabledKey] == true
end

local function hasEnabledSquareMinimapStats()
	if not addon.db then return false end
	for _, statKey in ipairs(squareMinimapStatsOrder) do
		if isSquareMinimapStatEnabled(statKey) then return true end
	end
	return false
end

local function shouldRunSquareMinimapStats() return shouldShowSquareMinimapStats() and hasEnabledSquareMinimapStats() end

local function getSquareMinimapStatsTickInterval()
	local shortest = nil
	for _, statKey in ipairs(squareMinimapStatsOrder) do
		if isSquareMinimapStatEnabled(statKey) then
			local interval = getSquareMinimapStatsInterval(statKey)
			if interval and interval > 0 and (not shortest or interval < shortest) then shortest = interval end
		end
	end
	if not shortest then return nil end
	return clamp(shortest, 0.1, 1.0)
end

local function handleSquareMinimapStatsEvent(event)
	if not shouldRunSquareMinimapStats() then return end
	local state = getSquareMinimapStatsState()
	if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
		if isSquareMinimapStatEnabled("location") then
			updateSquareMinimapStat("location")
			state.elapsed.location = 0
		end
		if isSquareMinimapStatEnabled("coordinates") then
			updateSquareMinimapStat("coordinates")
			state.elapsed.coordinates = 0
		end
		return
	end
	for _, statKey in ipairs(squareMinimapStatsOrder) do
		if isSquareMinimapStatEnabled(statKey) then
			updateSquareMinimapStat(statKey)
			state.elapsed[statKey] = 0
		end
	end
end

local function syncSquareMinimapStatsEvents()
	local state = getSquareMinimapStatsState()
	if not state.eventFrame then
		if not shouldRunSquareMinimapStats() then return end
		local frame = CreateFrame("Frame")
		frame:SetScript("OnEvent", function(_, event) handleSquareMinimapStatsEvent(event) end)
		state.eventFrame = frame
	end

	local frame = state.eventFrame
	if not frame then return end
	frame:UnregisterAllEvents()
	if not shouldRunSquareMinimapStats() then return end
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	if isSquareMinimapStatEnabled("location") or isSquareMinimapStatEnabled("coordinates") then
		frame:RegisterEvent("ZONE_CHANGED")
		frame:RegisterEvent("ZONE_CHANGED_INDOORS")
		frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	end
end

local function updateSquareMinimapStatsTicker(delta)
	if not shouldRunSquareMinimapStats() then
		hideSquareMinimapStats()
		stopSquareMinimapStatsTicker()
		syncSquareMinimapStatsEvents()
		return
	end

	local state = getSquareMinimapStatsState()
	for _, statKey in ipairs(squareMinimapStatsOrder) do
		if isSquareMinimapStatEnabled(statKey) then
			local interval = getSquareMinimapStatsInterval(statKey)
			if interval and interval > 0 then
				state.elapsed[statKey] = (state.elapsed[statKey] or 0) + delta
				if state.elapsed[statKey] >= interval then
					state.elapsed[statKey] = 0
					updateSquareMinimapStat(statKey)
				end
			else
				state.elapsed[statKey] = 0
			end
		else
			state.elapsed[statKey] = 0
			local frame = state.frames[statKey]
			if frame then frame:Hide() end
		end
	end
end

local function ensureSquareMinimapStatsTicker()
	local state = getSquareMinimapStatsState()
	local desiredInterval = getSquareMinimapStatsTickInterval()
	if not desiredInterval then
		stopSquareMinimapStatsTicker()
		return
	end
	if state.ticker and state.tickerInterval and math.abs(state.tickerInterval - desiredInterval) < 0.001 then return end
	stopSquareMinimapStatsTicker()
	state.tickerInterval = desiredInterval
	state.ticker = C_Timer.NewTicker(desiredInterval, function() updateSquareMinimapStatsTicker(desiredInterval) end)
end

function addon.functions.applySquareMinimapStats(force)
	ensureSquareMinimapStatsDefaults()
	if not Minimap then return end

	local state = getSquareMinimapStatsState()
	if force then state.renderConfig = {} end
	if addon.functions.applySquareMinimapTrackingButton then addon.functions.applySquareMinimapTrackingButton() end
	syncSquareMinimapStatsEvents()
	if not shouldRunSquareMinimapStats() then
		hideSquareMinimapStats()
		stopSquareMinimapStatsTicker()
		return
	end

	ensureSquareMinimapStatsTicker()

	for _, statKey in ipairs(squareMinimapStatsOrder) do
		if force then state.elapsed[statKey] = 0 end
		if isSquareMinimapStatEnabled(statKey) then
			updateSquareMinimapStat(statKey)
		else
			state.elapsed[statKey] = 0
			local frame = state.frames[statKey]
			if frame then frame:Hide() end
		end
	end
end

function addon.functions.initMapNav()
	addon.functions.applySquareMinimapLayout()
	if addon.functions.applySquareMinimapStats then addon.functions.applySquareMinimapStats(true) end
	if addon.functions.applyMinimapClusterClamp then addon.functions.applyMinimapClusterClamp() end
	if addon.functions.applyMinimapButtonMouseover then addon.functions.applyMinimapButtonMouseover() end
	addon.functions.EnableWorldMapCoordinates()
end

local eventHandlers = {}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
