local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL_SharedMedia")

addon.SharedMedia = addon.SharedMedia or {}
addon.SharedMedia.functions = addon.SharedMedia.functions or {}

local sharedMediaCategory = nil

local function ToggleSound(sound, value)
	addon.SharedMedia.functions.UpdateSound(sound.key, value and true or false)
	if value and not sound.bulkUpdate and sound.path then PlaySoundFile(sound.path, "Master") end
end

local function SanitizeVar(key) return (tostring(key):gsub("[^%w_]", "_")) end

local function CreateSoundSection(title, varPrefix, sounds)
	if not sounds or #sounds == 0 then return end
	local pageKey = varPrefix == "SharedMediaDeepVoice" and "SharedMediaDeepVoiceSounds" or "SharedMedia"

	local section = addon.functions.SettingsCreateExpandableSection(sharedMediaCategory, {
		name = title,
		configPageKey = pageKey,
		iconKey = "soundsettings",
		expanded = false,
		colorizeTitle = false,
		modernCategory = "sound",
		modernOnly = true,
	})

	local soundSettings = {}
	local bulkUpdate = false

	local function CreateButton(data)
		data.parentSection = section
		return addon.functions.SettingsCreateButton(sharedMediaCategory, data)
	end

	local function CreateCheckbox(data)
		data.parentSection = section
		return addon.functions.SettingsCreateCheckbox(sharedMediaCategory, data)
	end

	local function SetAllSounds(state)
		bulkUpdate = true
		for _, setting in pairs(soundSettings) do
			if setting and setting.SetValue then setting:SetValue(state and true or false) end
		end
		bulkUpdate = false
	end

	CreateButton({
		var = varPrefix .. "EnableAll",
		text = L["Enable All"],
		func = function() SetAllSounds(true) end,
		refreshOnChange = true,
	})

	CreateButton({
		var = varPrefix .. "DisableAll",
		text = L["Disable All"],
		func = function() SetAllSounds(false) end,
		refreshOnChange = true,
	})

	for _, sound in ipairs(sounds) do
		local entry = CreateCheckbox({
			var = varPrefix .. "Sound_" .. SanitizeVar(sound.key),
			text = sound.label,
			newTagID = sound.newTagID,
			get = function() return addon.db.sharedMediaSounds[sound.key] and true or false end,
			func = function(value)
				sound.bulkUpdate = bulkUpdate
				ToggleSound(sound, value)
				sound.bulkUpdate = nil
			end,
			default = false,
		})
		if entry and entry.setting then soundSettings[sound.key] = entry.setting end
	end
end

CreateSoundSection(L["SharedMedia"], "SharedMedia", addon.SharedMedia.sounds)
CreateSoundSection(L["SharedMediaDeepVoiceSounds"], "SharedMediaDeepVoice", addon.SharedMedia.deepVoiceSounds)
