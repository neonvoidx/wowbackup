local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local M = {}

function M.Read(key)
	if not (C_CVar and C_CVar.GetCVar) then return nil end
	local ok, value = pcall(C_CVar.GetCVar, key)
	if ok then return value end
end

function M.Write(key, value)
	if not (C_CVar and C_CVar.SetCVar) then return false end
	local ok = pcall(C_CVar.SetCVar, key, value)
	local actual = M.Read(key)
	return ok and actual ~= nil and (tostring(actual) == tostring(value) or (tonumber(actual) ~= nil and tonumber(actual) == tonumber(value)))
end

function M.Backups()
	-- CVars belong to the client, so restoration must survive profile changes.
	local db = addon.functions.GetPrivateDB()
	db.graphicsCVarRestore = db.graphicsCVarRestore or {}
	return db.graphicsCVarRestore
end

function M.Restore(id)
	local backups = M.Backups()
	local saved = backups[id]
	if not saved then return end
	for key, value in pairs(saved) do
		if M.Write(key, value) then saved[key] = nil end
	end
	-- Keep values that could not be restored so the user can retry.
	if next(saved) == nil then backups[id] = nil end
end

function M.SetPreset(id, values, enabled)
	if not enabled then return M.Restore(id) end
	local backups = M.Backups()
	if backups[id] then return end
	local saved = {}
	for key in pairs(values) do
		local value = M.Read(key)
		if value == nil then return end
		saved[key] = value
	end
	backups[id] = saved
	for key, value in pairs(values) do
		if not M.Write(key, value) then
			M.Restore(id)
			return
		end
	end
end

local category = addon.SettingsLayout.rootGENERAL
local section = addon.functions.SettingsCreateExpandableSection(category, {
	name = L["gameCVarOptions"],
	configPageKey = "GameCVarOptions",
	iconKey = "uiutilities",
	modernOnly = true,
	expanded = false,
	colorizeTitle = false,
	newTagID = "gameCVarOptions",
})

function M.Toggle(id, key, trueValue, falseValue)
	addon.functions.SettingsCreateCheckbox(category, {
		id = id,
		var = id,
		key = false,
		storage = false,
		trackCustomized = false,
		text = L[id],
		desc = L[id .. "Desc"],
		get = function() return M.Read(key) == trueValue end,
		func = function(enabled) M.Write(key, enabled and trueValue or falseValue) end,
		default = function()
			if not (C_CVar and C_CVar.GetCVarDefault) then return false end
			local ok, value = pcall(C_CVar.GetCVarDefault, key)
			return ok and value == trueValue
		end,
		hiddenWhen = function() return M.Read(key) == nil end,
		parentSection = section,
		newTagID = id,
	})
end

function M.Preset(id, values)
	addon.functions.SettingsCreateCheckbox(category, {
		id = id,
		var = id,
		key = false,
		storage = false,
		trackCustomized = false,
		text = L[id],
		desc = L[id .. "Desc"],
		get = function() return M.Backups()[id] ~= nil end,
		func = function(enabled) M.SetPreset(id, values, enabled) end,
		default = false,
		hiddenWhen = function()
			if M.Backups()[id] then return false end
			for key in pairs(values) do
				if M.Read(key) == nil then return true end
			end
			return false
		end,
		parentSection = section,
		newTagID = id,
	})
end

addon.functions.SettingsCreateSectionHeader(category, L["General"], { parentSection = section, id = "gameCVarGeneral", headerStyle = "subtle" })
M.Toggle("showInGameNavigation", "showInGameNavigation", "1", "0")
M.Toggle("autoAddNewSpells", "AutoPushSpellToActionBar", "1", "0")
M.Preset("slowCameraRotation", { cameraYawMoveSpeed = "60", cameraPitchMoveSpeed = "60" })
M.Toggle("hideLuaErrorWindow", "scriptErrors", "0", "1")

addon.functions.SettingsCreateSectionHeader(category, L["Effects"], { parentSection = section, id = "gameCVarEffects", headerStyle = "subtle" })
M.Preset("graphicsDenseVegetation", { groundEffectDensity = "256", groundEffectDist = "500", groundEffectFade = "500" })
M.Preset("graphicsExtendedDetail", { wmoLodDist = "1000", lodObjectCullSize = "1", terrainLodDist = "1000" })
M.Toggle("lootSparklesWithoutOutlines", "outlineModeShowLootEffectWhenDisabled", "1", "0")

if addon.variables and addon.variables.isForever then
	addon.functions.SettingsCreateSectionHeader(category, L["weatherDensity"], { parentSection = section, id = "gameCVarWeather", headerStyle = "subtle" })
	addon.functions.SettingsCreateCheckbox(category, {
		var = "weatherDensityEnabled",
		text = L["weatherDensityEnabled"],
		desc = L["weatherDensityEnabledDesc"],
		get = function() return addon.db and addon.db.weatherDensityEnabled == true end,
		func = function(enabled) addon.db.weatherDensityEnabled = enabled == true end,
		default = false,
		parentSection = section,
		newTagID = "weatherDensityEnabled",
	})
	addon.functions.SettingsCreateDropdown(category, {
		id = "weatherDensity",
		var = "weatherDensity",
		key = false,
		storage = false,
		trackCustomized = false,
		text = L["weatherDensity"],
		desc = L["weatherDensityDesc"],
		list = { [0] = L["weatherDensityVeryLow"], [1] = _G.LOW, [2] = _G.MEDIUM, [3] = _G.HIGH },
		order = { 0, 1, 2, 3 },
		get = function() return tonumber(M.Read("weatherDensity")) end,
		isEnabled = function()
			return addon.db and addon.db.weatherDensityEnabled == true and M.Read("weatherDensity") ~= nil and M.Read("RAIDweatherDensity") ~= nil
		end,
		func = function(value)
			-- Only an explicit selection may change the client's current settings.
			if not (addon.db and addon.db.weatherDensityEnabled == true) then return end
			value = tonumber(value)
			if not value or value < 0 or value > 3 or value ~= math.floor(value) then return end
			if M.Read("weatherDensity") == nil or M.Read("RAIDweatherDensity") == nil then return end
			M.Write("weatherDensity", tostring(value))
			M.Write("RAIDweatherDensity", tostring(value))
		end,
		parentSection = section,
		newTagID = "weatherDensity",
	})
end
