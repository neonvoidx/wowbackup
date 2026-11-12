local parentAddonName = "EnhanceQoL"
local _, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local UF = addon.Aura and addon.Aura.UF
if not UF then return end
UF.ui = UF.ui or {}

function UF.ui.BuildSettingsNavigation()
	local castSections = {
		[L["Bar style"]] = { "castStyle", L["Bar style"] },
		[L["Background"]] = { "castStyle", L["Bar style"] },
		[L["Border"]] = { "castStyle", L["Bar style"] },
		[L["Icon"]] = { "castIcon", L["Icon"] },
		[L["Icon border"]] = { "castIcon", L["Icon"] },
		[L["Text"]] = { "castText", L["Text"] },
		[L["Name"]] = { "castText", L["Text"] },
		[L["Duration"]] = { "castDuration", L["Duration"] },
		[L["Interrupt feedback"]] = { "castFeedback", L["Interrupt feedback"] },
	}
	return {
		categories = {
			{ id = "frame", name = L["Frame"], groups = { "frame", "layout", "border", "highlight", "portrait", "stance", "rangeFade", "utility" } },
			{ id = "health", name = L["Health"], groups = { "health", "healthText", "incomingHeal", "absorb", "healAbsorb", "npcColors" } },
			{ id = "power", name = L["Power"], groups = { "power", "powerText", "secondaryPower", "secondaryPowerText", "secondaryPowerStaggerColors" } },
			{ id = "text", name = L["UFNavNameStatus"], groups = { "name", "level", "statusText" } },
			{ id = "indicators", name = L["UFNavIndicators"], groups = { "unitStatus", "dispelTint", "raidicon", "combatFeedback" } },
			{ id = "auras", name = L["Auras"], groups = { "buffs", "debuffs" } },
			{ id = "cast", name = L["Castbar"], groups = { "cast" } },
			{ id = "classResource", name = L["ClassResource"], groups = { "classResource" } },
			{ id = "totemFrame", name = L["Totem Frame"], groups = { "totemFrame" } },
			{ id = "dataBar", name = L["UFDataBar"], groups = { "dataBar" } },
		},
		tabNames = {
			frame = L["General"], utility = L["Copy settings"], health = L["Bar"], healthText = L["Text"], power = L["Bar"], powerText = L["Text"],
		},
		splitGroups = {
			totemFrame = function(data)
				if data.navigationTab == "totemIcon" then return "totemIcon", L["Icon"] end
				if data.navigationTab == "totemDuration" then return "totemDuration", L["Duration"] end
				if data.navigationTab == "totemName" then return "totemName", L["Name"] end
				return "totemGeneral", L["General"]
			end,
			cast = function(_, section)
				local tab = castSections[section]
				if tab then return tab[1], tab[2] end
				return "castBar", L["Bar"]
			end,
			dataBar = function(data)
				if data.navigationTab == "dataBarText" then return "dataBarText", L["Text"] end
				return "dataBarBar", L["Bar"]
			end,
			name = function(data)
				if data.navigationTab == "targetTargetName" then return "targetTargetName", L["UFToTFrame"] end
				return "name", _G.NAME or L["Name"]
			end,
			statusText = function(_, section)
				if section == L["Group number"] then return "groupNumber", L["Group number"] end
				return "statusText", L["Status text"]
			end,
		},
		visibilityHint = function(data)
			local hints = UF.ui.navigationHints
			return data.navigationHint or (hints and data.isShown and hints[data.isShown])
		end,
		reset = function(tab, applyDefaults)
			if UF.ui.RunSettingsReset then return UF.ui.RunSettingsReset(applyDefaults, tab) end
			local wasResetting = UF.ui.navigationResetting
			UF.ui.navigationResetting = true
			local ok, err = pcall(applyDefaults, tab)
			UF.ui.navigationResetting = wasResetting
			if not ok then error(err) end
		end,
	}
end
