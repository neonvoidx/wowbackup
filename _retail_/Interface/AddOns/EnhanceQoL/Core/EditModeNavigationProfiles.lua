local _, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local Profiles = {}
addon.EditModeNavigationProfiles = Profiles

local function category(id, name, groups) return { id = id, name = name, groups = groups } end

local function fieldOf(data) return data.navigationField or data.field or "" end

local function append(target, values)
	for _, value in ipairs(values) do target[#target + 1] = value end
end

local function collectGroups(settings)
	local ids, headers = {}, {}
	local types = addon.EditModeLib.SettingType
	for _, data in ipairs(settings or {}) do
		if data.kind == types.Collapsible and data.id and not headers[data.id] then
			ids[#ids + 1] = data.id
			headers[data.id] = data
		end
	end
	return ids, headers
end

local function canReset(tab)
	if tab and tab.header and type(tab.header.navigationReset) == "function" then return true end
	local found = false
	local types = addon.EditModeLib.SettingType
	for _, data in ipairs(tab and tab.settings or {}) do
		if not data.navigationSearchExcluded and not data.navigationResetExcluded and data.kind ~= types.Divider and data.kind ~= types.Label and data.kind ~= types.Collapsible then
			if data.set or data.colorSet or data.setColor or data.navigationReset or data.generator then
				-- Several integrations register current values as defaults. Only an
				-- explicit reset or verified factory defaults can reset an entire tab.
				if type(data.navigationReset) ~= "function" and data.navigationDefaultVerified ~= true then return false end
				if not data.navigationReset and data.default == nil and data.colorDefault == nil then return false end
				found = true
			end
		end
	end
	return found
end

local function newProfile()
	return { categories = {}, tabNames = {}, splitGroups = {}, canReset = canReset }
end

local function resourceBarProfile()
	local profile = newProfile()
	profile.categories = {
		category("frame", L["Frame"], { "resourceAnchor", "resourceFrame", "resourceVisibility", "CheckboxGroup" }),
		category("bar", L["Bar"], { "resourceBar", "absorb", "healabsorb", "resourceBorder" }),
		category("text", L["Text"], { "textsettings" }),
		category("colors", L["Colors"], { "colorsetting", "powercolorsetting", "staggercolors" }),
		category("thresholds", L["EditModeNavThresholds"], { "resourceThresholds", "absolutethresholdcolors", "textthresholdcolors" }),
		category("settings", L["Settings"], { "profiles" }),
	}
	profile.splitGroups.frame = function(data)
		local field = fieldOf(data)
		if field:find("^anchor") or field:find("^matchRelative") or field:find("^dynamicAnchor") then return "resourceAnchor", L["Anchor"] end
		if field == "visibility" or field:find("^visibility") or field == "showForms"
			or field == "separateCombatOpacity" or field == "opacityInCombat" or field == "opacityOutOfCombat"
			or data.name == L["Hide in vehicles"] or data.name == L["Hide in pet battles"]
			or data.name == L["ResourceBarsHideWhenEmpty"] or data.name == L["Hide in client scenes"] then
			return "resourceVisibility", L["Visibility"]
		end
		if field:find("^threshold") or field == "showThresholds" or field == "useAbsoluteThresholds" then
			return "resourceThresholds", L["EditModeNavThresholds"]
		end
		if field == "width" or field == "height" or field == "strata" or field == "frameLevelOffset" or field == "clickThrough" then
			return "resourceFrame", L["General"]
		end
		return "resourceBar", L["Bar"]
	end
	profile.splitGroups.CheckboxGroup = function(data)
		local field = fieldOf(data)
		if field == "backdropBorder" or field == "backdropEdgeSize" or field == "backdropOutset" then return "resourceBorder", L["Border"] end
		return "CheckboxGroup", L["Background"]
	end
	profile.tabNames.CheckboxGroup = L["Background"]
	return profile
end

local function progressBarProfile(id)
	local profile = newProfile()
	profile.categories = {
		category("frame", L["Frame"], { id .. "Anchor", id .. "Visibility", id .. "Frame" }),
		category("display", L["Display"], { id .. "Bar", id .. "Background", id .. "Border" }),
		category("text", L["Text"], { id .. "Text", id .. "Label" }),
	}
	profile.splitGroups[id .. "Text"] = function(data)
		local field = fieldOf(data)
		for _, side in ipairs(id == "xpBar" and { "Left", "Center", "Right", "Extra1", "Extra2" } or { "Left", "Center", "Right" }) do
			if field:find("^text" .. side) then return id .. "Text" .. side, (side:find("Extra", 1, true) and L["xpBarText" .. side] or L[side .. " text"]) end
		end
		return id .. "TextStyle", L["General"]
	end
	return profile
end

local function gcdBarProfile()
	local profile = newProfile()
	profile.categories = {
		category("frame", L["Frame"], { "gcdAnchor", "gcdFrame", "gcdVisibility" }),
		category("display", L["Display"], { "gcdBar", "gcdBackground", "gcdBorder" }),
	}
	profile.splitGroups.__general = function(data)
		local field = fieldOf(data)
		if field:find("^anchor") or field:find("^dynamicAnchor") then return "gcdAnchor", L["Anchor"] end
		if field == "hideInPetBattle" then return "gcdVisibility", L["Visibility"] end
		if field == "strata" or field == "width" or field == "height" then return "gcdFrame", L["General"] end
		if field:find("^bg") then return "gcdBackground", L["Background"] end
		if field:find("^border") then return "gcdBorder", L["Border"] end
		return "gcdBar", L["Bar"]
	end
	return profile
end

local function damageMeterProfile(ids)
	local profile = newProfile()
	local groups = { frame = {}, bar = {}, text = {}, behavior = {} }
	for _, id in ipairs(ids) do
		if id:find("^damageMeterBar%d+$") or id:find("^damageMeterIcon%d+$") then
			groups.bar[#groups.bar + 1] = id
			if id:find("^damageMeterBar%d+$") then
				profile.splitGroups[id] = function(_, section)
					if section == L["Display"] then return id .. "Display", L["Display"] end
					if section == L["Background"] then return id .. "Background", L["Background"] end
					if section == L["damageMeterRowBorder"] or section == L["damageMeterBarBorder"] then return id .. "Border", L["Border"] end
					return id .. "Layout", L["Layout"]
				end
			end
		elseif id:find("^damageMeterNames%d+$") or id:find("^damageMeterValues%d+$") or id:find("^damageMeterRanking%d+$") then
			groups.text[#groups.text + 1] = id
		elseif id:find("^damageMeterBehavior%d+$") or id:find("^damageMeterTooltip%d+$") or id:find("^damageMeterSettings%d+$") then
			groups.behavior[#groups.behavior + 1] = id
		else
			groups.frame[#groups.frame + 1] = id
		end
	end
	profile.categories = {
		category("frame", L["Frame"], groups.frame),
		category("bar", L["Bar"], groups.bar),
		category("text", L["Text"], groups.text),
		category("behavior", L["Behavior"], groups.behavior),
	}
	return profile
end

local function dataPanelProfile()
	local profile = newProfile()
	profile.categories = {
		category("streams", L["DataPanelStreams"], { "dataPanelStreams" }),
		category("frame", L["Frame"], { "dataPanelLayout", "dataPanelAnchor", "dataPanelBackground", "dataPanelBorder" }),
		category("text", L["Text"], { "dataPanelText" }),
		category("behavior", L["Behavior"], { "dataPanelTooltip" }),
	}
	return profile
end

local function timerProfile()
	local profile = newProfile()
	profile.categories = {
		category("frame", L["Frame"], { "mpt-layout", "mpt-flow-layout", "mythicPlusTimerAnchor", "mpt-background", "mpt-header-bar", "mpt-footer-bar", "mpt-flow-header", "mpt-flow-footer", "mpt-border" }),
		category("display", L["Display"], { "mpt-display", "mpt-panel-dungeon-key", "mpt-panel-time", "mpt-panel-deaths", "mpt-panel-enemy", "mpt-panel-best", "mpt-panel-objectives", "mpt-panel-affixes" }),
		category("text", L["Text"], { "mpt-font", "mpt-flow-font", "mpt-colors" }),
		category("bar", L["Bar"], { "mpt-bars", "mpt-flow-timer", "mpt-flow-objectives", "mpt-flow-enemy" }),
		category("behavior", L["Behavior"], { "mpt-behavior" }),
	}
	return profile
end

local function classBuffProfile()
	local profile = newProfile()
	profile.categories = {
		category("tracking", L["settingsCategoryTracking"], { "classBuffs", "filters", "pets" }),
		category("consumables", L["categoryConsumables"], { "flasks", "food", "runes", "weaponBuffs", "poisons" }),
		category("warnings", L["ClassBuffReminderWarningTimes"], { "expirationCategories" }),
		category("iconPresentation", L["ClassBuffReminderIconTextGlow"], { "iconPresentation" }),
		category("frame", L["Frame"], { "classBuffReminderAnchor", "anchorSize", "border" }),
		category("sound", _G.SOUND or L["ProfileImportProtectionSound"], { "sound" }),
	}
	return profile
end

local function trackerProfile(id, ids)
	local profile = newProfile()
	local frame, text, behavior = {}, {}, {}
	for _, groupId in ipairs(ids) do
		local suffix = groupId:sub(#id + 1)
		if suffix == "Text" or suffix == "Cooldown" or suffix == "Charges" or suffix == "Ready" then
			text[#text + 1] = groupId
		elseif suffix == "Sound" or suffix == "General" then
			behavior[#behavior + 1] = groupId
		else
			frame[#frame + 1] = groupId
		end
	end
	profile.categories = {
		category("frame", L["Frame"], frame),
		category("text", L["Text"], text),
		category("behavior", L["Behavior"], behavior),
	}
	return profile
end

local function defaultAuraProfile()
	local profile = newProfile()
	profile.categories = {
		category("frame", L["Frame"], { "default-aura-containers-layout", "default-aura-containers-border" }),
		category("text", L["Text"], { "default-aura-containers-duration", "default-aura-containers-stacks" }),
	}
	return profile
end

function Profiles.Get(id, opts)
	opts = opts or {}
	id = tostring(id or "")
	if addon.EditModeNavigationSmallFrames then
		local profile = addon.EditModeNavigationSmallFrames.Get(id, opts)
		if profile then return profile end
	end
	if opts.managerCategory == "unitFrames" then return nil end
	local ids = collectGroups(opts.settings)
	if id:find("^resourceBar_") then return resourceBarProfile() end
	if id == "gcdBar" then return gcdBarProfile() end
	if id == "xpBar" or id == "honorBar" or id == "repBar" or id:find("^swingBar") then return progressBarProfile(id) end
	if opts.managerCategory == "damageMeter" or id:find("^EQOL_DamageMeter") then return damageMeterProfile(ids) end
	if opts.managerCategory == "dataPanels" or id:find("^dataPanel:") then return dataPanelProfile() end
	if id == "EQOL_MythicPlusTimer" then return timerProfile() end
	if id == "classBuffReminder" then return classBuffProfile() end
	if id == "DefaultAuraBuffContainer" or id == "DefaultAuraDebuffContainer" then return defaultAuraProfile() end
	if id == "focusInterruptTracker" or id == "totalAbsorbTracker" or id == "mythicPlusBRTracker" or id == "mythicPlusBloodlustTracker" then return trackerProfile(id, ids) end
	local profile = newProfile()
	local groups = { "__general" }
	append(groups, ids)
	profile.categories = { category("general", L["General"], groups) }
	profile.direct = #ids <= 1
	return profile
end
