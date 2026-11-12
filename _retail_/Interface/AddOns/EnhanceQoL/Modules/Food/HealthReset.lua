local addon = _G.EnhanceQoL
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local R = {}
addon.Health.Reset = R

function R.Normalize(db)
	local selection = db.healthReset
	if type(selection) ~= "table" then
		local seconds = tonumber(selection)
		if seconds then
			selection = { time = true }
			db.healthResetSeconds = seconds
		elseif selection == "target" then
			selection = { target = true }
		else
			selection = { combat = true }
		end
		db.healthReset = selection
	end
	if db.healthResetOnCombatEnd then selection.combat = true end
	db.healthResetOnCombatEnd = nil
	db.healthResetSeconds = math.max(1, math.min(600, math.floor(tonumber(db.healthResetSeconds) or 60)))
	return selection
end

function R.GetClass()
	local name, token
	if UnitClass then name, token = UnitClass("player") end
	token = addon.variables and addon.variables.unitClass or token
	return token, name or (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token
end

function R.GetClassOverride(db, token, create)
	if not token then return nil end
	local overrides = db.healthResetByClass
	local config = type(overrides) == "table" and overrides[token] or nil
	if type(config) ~= "table" and create and token then
		local selection = R.Normalize(db)
		config = { enabled = false, healthReset = {}, healthResetSeconds = db.healthResetSeconds }
		for key, selected in pairs(selection) do if selected == true then config.healthReset[key] = true end end
		if type(overrides) ~= "table" then overrides = {}; db.healthResetByClass = overrides end
		overrides[token] = config
	end
	return type(config) == "table" and config or nil
end

function R.GetConfig(db, token)
	if not token then token = R.GetClass() end
	local config = token and R.GetClassOverride(db, token)
	if config and config.enabled == true then return config end
	return db
end

function R.BuildToken(db, token)
	local config = R.GetConfig(db, token)
	local selection = R.Normalize(config)
	local parts = {}
	if selection.time == true then parts[#parts + 1] = tostring(config.healthResetSeconds) end
	if selection.combat == true then parts[#parts + 1] = "combat" end
	if selection.target == true then parts[#parts + 1] = "target" end
	return table.concat(parts, "/")
end

function R.RegisterSettings(category, section, enabled)
	local function addRules(prefix, getConfig, label, visible)
		addon.functions.SettingsCreateMultiDropdown(category, {
			var = prefix, storage = false,
			text = label, desc = L["healthResetDesc"],
			options = {
				{ value = "combat", text = L["Reset: Combat"] },
				{ value = "target", text = L["Reset: Target"] },
				{ value = "time", text = L["healthResetAfterTime"] },
			},
			default = { combat = true }, emptyText = _G.NONE,
			get = function() return R.Normalize(getConfig()) end,
			set = function(selection)
				local config = getConfig(true)
				config.healthReset = selection
				R.Normalize(config)
				addon.Health.functions.updateHealthMacro(false)
			end,
			parentCheck = enabled, parentSection = section,
			hiddenWhen = visible and function() return not visible() end or nil,
			refreshOnChange = true, newTagID = prefix == "healthReset" and "healthResetConditions" or prefix,
		})
		addon.functions.SettingsCreateSlider(category, {
			var = prefix == "healthReset" and "healthResetSeconds" or "healthResetClassSeconds", storage = false,
			text = L["healthResetSeconds"], desc = L["healthResetDesc"],
			min = 1, max = 600, step = 1, default = 60,
			get = function() local config = getConfig(); R.Normalize(config); return config.healthResetSeconds end,
			set = function(value)
				local config = getConfig(true)
				config.healthResetSeconds = value
				R.Normalize(config)
				addon.Health.functions.updateHealthMacro(false)
			end,
			hiddenWhen = function() return (visible and not visible()) or R.Normalize(getConfig()).time ~= true end,
			parentCheck = enabled, parentSection = section,
			newTagID = prefix == "healthReset" and "healthResetSeconds" or "healthResetClassSeconds",
		})
	end
	local token, className = R.GetClass()
	if not token then
		addRules("healthReset", function() return addon.db end, L["healthResetDefaultConditions"])
		return
	end
	local function hasOverride()
		local config = R.GetClassOverride(addon.db, token)
		return config and config.enabled == true or false
	end
	addon.functions.SettingsCreateCheckbox(category, {
		var = "healthResetClassOverride", storage = false,
		text = string.format(L["healthResetClassOverride"], className),
		desc = L["healthResetClassOverrideDesc"],
		default = false, get = hasOverride,
		func = function(value)
			local config = R.GetClassOverride(addon.db, token, true)
			config.enabled = value == true
			addon.Health.functions.updateHealthMacro(false)
		end,
		parentCheck = enabled, parentSection = section,
		refreshOnChange = true, newTagID = "healthResetClassOverride",
	})
	addon.functions.SettingsCreateSectionHeader(category, L["healthResetDefaultConditions"], {
		parentSection = section, headerStyle = "subtle", hiddenWhen = hasOverride,
	})
	addon.functions.SettingsCreateSectionHeader(category, className, {
		parentSection = section, headerStyle = "subtle", hiddenWhen = function() return not hasOverride() end,
	})
	addRules("healthReset", function() return addon.db end, L["Reset condition"], function() return not hasOverride() end)
	addRules("healthResetClassConditions", function(create) return R.GetClassOverride(addon.db, token, create) or addon.db end, L["Reset condition"], hasOverride)
end
