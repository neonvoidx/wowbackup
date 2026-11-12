local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName]
if not addon then error(parentAddonName .. " is not loaded") end
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local QC = addon.QuickCast
local Navigation = {}
QC.Navigation = Navigation

local menuFields = {
	quickCastMenuGeneral = { "enabled", "showTooltips" },
	quickCastMenuVisibility = { "specFilter", "hideDefaultAction", "hideOnCooldown", "hideMissingItems" },
	quickCastMenuLayout = { "layout", "direction", "anchor", "spacing", "radialSpacingOffset", "showAtCursor", "offsetX", "offsetY" },
	quickCastMenuIcon = { "iconSize", "iconShape", "iconZoom", "showCraftingQuality" },
	quickCastMenuBorder = { "iconBorderEnabled", "iconBorderColor", "iconBorderUseItemQualityColor", "iconBorderTexture", "iconBorderSize", "iconBorderOffset" },
	quickCastMenuTitle = { "showTitle", "titleFont", "titleAnchor", "titleFontSize", "titleFontOutline", "titleUseClassColor", "titleColor", "titleOffsetX", "titleOffsetY" },
	quickCastMenuLabels = { "showLabels", "labelFont", "labelFontSize", "labelFontOutline", "labelColor", "labelCharacterLimit", "labelAnchor", "labelOffsetX", "labelOffsetY" },
	quickCastMenuCounts = { "countFont", "countFontSize", "countFontOutline", "countColor", "countAnchor", "countOffsetX", "countOffsetY" },
}
local function category(id, name, groups) return { id = id, name = name, groups = groups } end
local function hint(data, target)
	if not target then return end
	data.navigationHint = function()
		if target.isShown and not target.isShown() and target.navigationHint then return target.navigationHint() end
		return target.name, nil, target.parentId
	end
end

function Navigation.Build(settings, kind, menuID, entryID, helpers)
	local types = addon.EditModeLib.SettingType
	local controls, headers = {}, {}
	local borderStarted = false
	for _, data in ipairs(settings) do
		if data.kind == types.Collapsible then headers[data.id] = data else
			if data.parentId == "quickCastMenuIcon" then
				if data.name == L["Border"] then borderStarted = true end
				if borderStarted then data.parentId = "quickCastMenuBorder" end
			end
			local group = data.parentId
			controls[group] = controls[group] or {}
			if data.name then controls[group][data.name] = data end
		end
	end
	if controls.quickCastMenuBorder and not headers.quickCastMenuBorder then
		local header = { kind = types.Collapsible, id = "quickCastMenuBorder", name = L["Border"] }
		settings[#settings + 1], headers[header.id] = header, header
		local labels = { [L["Border texture"]] = L["Texture"], [L["Border size"]] = L["Size"], [L["Border offset"]] = L["Offset"] }
		for _, data in ipairs(settings) do
			if data.parentId == header.id then data.name = labels[data.name] or data.name end
		end
	end
	for _, data in ipairs(settings) do
		if data.isShown and data.kind ~= types.Collapsible then
			local group = controls[data.parentId] or {}
			if data.parentId == "quickCastMenuTitle" then
				data.navigationHint = function()
					local menu = helpers.getMenu(menuID)
					local target = group[L["QuickCastShowTitle"]]
					if menu and menu.showTitle and data.name == L["Font color"] then target = group[L["Use class color"]] end
					if target and target ~= data then return target.name, nil, target.parentId end
				end
			elseif data.parentId == "quickCastMenuLayout" then hint(data, group[L["QuickCastLayout"]]) end
		end
	end
	for id, header in pairs(headers) do
		if kind == "menu" and menuFields[id] then
			header.navigationReset = function()
				if not helpers.isEditingAllowed() then return end
				local menu = helpers.getMenu(menuID)
				if not menu then return end
				local defaults = QC:GetMenuDefaults()
				for _, field in ipairs(menuFields[id]) do menu[field] = helpers.copy(defaults[field]) end
				helpers.refreshRuntime(true, menuID)
			end
		elseif kind == "entry" then
			header.navigationReset = function()
				helpers.mutateAction(menuID, entryID, function(action)
					if id == "quickCastActionGeneral" then
						action.enabled, action.atCursor, action.showLabel, action.customLabel = true, nil, nil, nil
						local menu = helpers.getMenu(menuID)
						if menu and menu.defaultEntryID == action.entryID then menu.defaultEntryID = nil end
					elseif id == "quickCastActionVisibility" then helpers.ensureConditions(action).specs = nil
					elseif id == "quickCastActionInventory" then helpers.ensureConditions(action).inventory = { useMenu = true }
					elseif id == "quickCastActionCooldown" then helpers.ensureConditions(action).cooldown = { useMenu = true } end
				end, true)
			end
		end
	end
	if kind == "menu" then
		local starts = {
			quickCastMenuTitle = { [L["Use class color"]] = L["Colors"], [L["Offset X"]] = L["Position"] },
			quickCastMenuLabels = { [L["Font"]] = L["Font"], [L["Anchor"]] = L["Position"] },
			quickCastMenuCounts = { [L["Anchor"]] = L["Position"] },
			quickCastMenuLayout = { [L["QuickCastOffsetX"]] = L["Position"] },
		}
		local grouped, titleAnchor = {}, nil
		for _, data in ipairs(settings) do
			if data.parentId == "quickCastMenuTitle" and data.name == L["Anchor"] then titleAnchor = data end
		end
		for _, data in ipairs(settings) do
			if data ~= titleAnchor then
				local title = starts[data.parentId] and starts[data.parentId][data.name]
				if title then
					grouped[#grouped + 1] = { name = title, kind = types.Divider, parentId = data.parentId, isShown = data.isShown }
					if data.parentId == "quickCastMenuTitle" and title == L["Position"] and titleAnchor then grouped[#grouped + 1] = titleAnchor end
				end
				grouped[#grouped + 1] = data
			end
		end
		for index = #settings, 1, -1 do settings[index] = nil end
		for index, data in ipairs(grouped) do settings[index] = data end
	end
	local categories = kind == "menu" and {
		category("menu", L["General"], { "quickCastMenuGeneral", "quickCastMenuVisibility" }),
		category("layout", L["Layout"], { "quickCastMenuLayout" }),
		category("icon", L["Icon"], { "quickCastMenuIcon", "quickCastMenuBorder" }),
		category("text", L["Text"], { "quickCastMenuTitle", "quickCastMenuLabels", "quickCastMenuCounts" }),
	} or {
		category("action", L["General"], { "quickCastActionGeneral" }),
		category("visibility", L["Visibility"], { "quickCastActionVisibility", "quickCastActionInventory", "quickCastActionCooldown" }),
	}
	return { categories = categories, scopeKey = "quickActions:" .. kind .. ":" .. tostring(menuID) .. ":" .. tostring(entryID or ""),
		tabNames = { quickCastMenuGeneral = L["General"], quickCastActionGeneral = L["General"], quickCastMenuIcon = L["Icon"] } }
end
