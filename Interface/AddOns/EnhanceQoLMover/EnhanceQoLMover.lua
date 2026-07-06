local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local db

local perFramePositionPersistenceList = {
	global = {
		text = L["Position Persistence Global"] or "Use global setting",
		tooltip = L["Position Persistence Global Tooltip"] or "Uses the global position persistence setting.",
	},
	close = {
		text = L["Position Persistence Close"] or "Until close of the frame",
		tooltip = L["Position Persistence Close Tooltip"] or "Does not save the position and resets when the frame closes.",
	},
	lockout = {
		text = L["Position Persistence Lockout"] or "Until logout",
		tooltip = L["Position Persistence Lockout Tooltip"] or "Saves the position only until you log out.",
	},
	reset = {
		text = L["Position Persistence Reset"] or "Until reset",
		tooltip = L["Position Persistence Reset Tooltip"] or "Saves the position until you reset it.",
	},
	off = {
		text = L["Position Persistence Disabled"] or "Disabled",
		tooltip = L["Position Persistence Disabled Tooltip"] or "Does not save or restore a custom position for this frame.",
	},
}

local perFramePositionPersistenceOrder = { "global", "close", "lockout", "reset", "off" }

local function buildSettings()
	local categoryLabel = L["Move"] or "Mover"
	local cLayout = addon.SettingsLayout.rootUI

	local expandable = addon.functions.SettingsCreateExpandableSection(cLayout, {
		name = categoryLabel,
		iconKey = "mover",
		expanded = false,
		colorizeTitle = false,
		newTagID = "Mover",
	})

	local hintText = L["MoverResetHint"]
	if hintText and hintText ~= "" then addon.functions.SettingsCreateText(cLayout, "|cff99e599" .. hintText .. "|r", { parentSection = expandable }) end

	local sectionGeneral = expandable
	addon.functions.SettingsCreateHeadline(cLayout, {
		name = L["Global Settings"] or "General",
		parentSection = expandable,
	})

	local rootSettingKey = "moverEnabled"
	local rootElement

	local settings = addon.Mover.variables.settings or {}
	for _, def in ipairs(settings) do
		local kind = def.type or "checkbox"
		local data = {}
		for key, value in pairs(def) do
			if key ~= "type" and key ~= "dbKey" and key ~= "init" then data[key] = value end
		end
		data.parentSection = data.parentSection or sectionGeneral
		if def.var ~= rootSettingKey and rootElement then
			local originalParentCheck = data.parentCheck
			data.element = rootElement
			data.parent = true
			data.parentCheck = function() return db.enabled and (originalParentCheck == nil or originalParentCheck()) end
		end
		if kind == "checkbox" then
			local created = addon.functions.SettingsCreateCheckbox(cLayout, data)
			if def.var == rootSettingKey then rootElement = created and created.element or rootElement end
		elseif kind == "dropdown" then
			addon.functions.SettingsCreateDropdown(cLayout, data)
		elseif kind == "slider" then
			addon.functions.SettingsCreateSlider(cLayout, data)
		end
	end

	for _, group in ipairs(addon.Mover.functions.GetGroups()) do
		local parentSection = expandable
		local enableElement = rootElement
		addon.functions.SettingsCreateHeadline(cLayout, {
			name = group.label or group.id,
			parentSection = parentSection,
		})

		for _, entry in ipairs(addon.Mover.functions.GetEntriesForGroup(group.id)) do
			local e = entry
			addon.functions.SettingsCreateCheckboxDropdown(cLayout, {
				var = e.settingKey or e.id,
				text = e.label or e.id,
				default = e.defaultEnabled ~= false,
				get = function() return addon.Mover.functions.IsFrameEnabled(e) end,
				set = function(value)
					addon.Mover.functions.SetFrameEnabled(e, value)
					addon.Mover.functions.RefreshEntry(e)
				end,
				element = enableElement,
				parent = true,
				parentSection = parentSection,
				parentCheck = function() return db.enabled end,
				dropdownVar = (e.settingKey or e.id) .. "_positionPersistence",
				dropdownText = L["Position Persistence"] or "Position persistence",
				dropdownList = perFramePositionPersistenceList,
				dropdownOrder = perFramePositionPersistenceOrder,
				dropdownDefault = "global",
				dropdownGet = function() return addon.Mover.functions.GetFramePositionPersistence(e) end,
				dropdownSet = function(value) addon.Mover.functions.SetFramePositionPersistence(e, value) end,
			})
		end
	end
end

function addon.Mover.functions.InitSettings()
	if addon.Mover.variables.settingsBuilt then return end
	if not (addon.SettingsLayout and addon.SettingsLayout.rootUI and addon.functions and addon.functions.SettingsCreateExpandableSection) then return end
	db = addon.Mover.db
	if not db then return end
	buildSettings()
	addon.Mover.variables.settingsBuilt = true
end

function addon.Mover.functions.treeCallback(container, group)
	if addon.functions and addon.functions.OpenConfigCenter then addon.functions.OpenConfigCenter("interface.mover", "moverEnabled") end
end

if addon.Mover.functions.Initialize then addon.Mover.functions.Initialize() end
