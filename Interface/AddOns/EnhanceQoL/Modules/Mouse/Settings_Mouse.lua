local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local cMouse = addon.SettingsLayout.rootGENERAL

local expandable = addon.functions.SettingsCreateExpandableSection(cMouse, {
	name = L["MouseAndAccessibility"] or "Mouse & Accessibility",
	newTagID = "MouseAndAccessibility",
	configPageKey = "MouseAccessibility",
	iconKey = "mouseaccessibility",
	modernOnly = true,
	expanded = false,
	colorizeTitle = false,
})

addon.functions.SettingsCreateHeadline(cMouse, L["mouseRing"], { parentSection = expandable })

local function isRingEnabledSetting()
	return addon.SettingsLayout.elements["mouseRingEnabled"]
		and addon.SettingsLayout.elements["mouseRingEnabled"].setting
		and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
end

local function isRingSwipeStyleSetting()
	local db = addon.db or {}
	return (db["mouseRingProgressStyle"] or "DOT") == "RING"
end

local function isCastProgressEnabledSetting()
	return isRingEnabledSetting()
		and addon.SettingsLayout.elements["mouseRingCastProgress"]
		and addon.SettingsLayout.elements["mouseRingCastProgress"].setting
		and addon.SettingsLayout.elements["mouseRingCastProgress"].setting:GetValue() == true
end

local data = {
	{
		var = "mouseRingEnabled",
		text = L["mouseRingEnabled"],
		desc = L["mouseRingEnabledDesc"],
		func = function(v)
			addon.db["mouseRingEnabled"] = v
			if v then
				if addon.Mouse.functions.refreshRingVisibility then
					addon.Mouse.functions.refreshRingVisibility()
				else
					addon.Mouse.functions.createMouseRing()
				end
			else
				addon.Mouse.functions.removeMouseRing()
			end
			if addon.Mouse.functions.syncRingProgressState then addon.Mouse.functions.syncRingProgressState() end
			if addon.Mouse.functions.updateRunnerState then addon.Mouse.functions.updateRunnerState() end
		end,
		parentSection = expandable,
		children = {
			{
				var = "mouseRingSize",
				text = L["mouseRingSize"],
				desc = L["mouseRingSizeDesc"],
				get = function() return addon.db and addon.db.mouseRingSize or 70 end,
				set = function(v)
					addon.db["mouseRingSize"] = v
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
				end,
				min = 20,
				max = 200,
				step = 1,
				parent = true,
				default = 70,
				sType = "slider",
				parentSection = expandable,
			},
			{

				var = "mouseRingHideDot",
				text = L["mouseRingHideDot"],
				desc = L["mouseRingHideDotDesc"],
				func = function(v)
					addon.db["mouseRingHideDot"] = v
					if addon.mousePointer and addon.mousePointer.dot then
						if v then
							addon.mousePointer.dot:Hide()
						else
							addon.mousePointer.dot:Show()
						end
					elseif addon.mousePointer and not v then
						local dot = addon.mousePointer:CreateTexture(nil, "BACKGROUND")
						dot:SetTexture(addon.Mouse.variables.TEXT_DOT)
						dot:SetSize(10, 10)
						dot:SetPoint("CENTER", addon.mousePointer, "CENTER", 0, 0)
						addon.mousePointer.dot = dot
					end
					if not v and addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
			},
			{

				var = "mouseRingOnlyInCombat",
				text = L["mouseRingOnlyInCombat"],
				desc = L["mouseRingOnlyInCombatDesc"],
				func = function(v)
					addon.db["mouseRingOnlyInCombat"] = v
					if addon.Mouse.functions.refreshRingVisibility then addon.Mouse.functions.refreshRingVisibility() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
			},
			{
				var = "mouseRingOnlyOnRightClick",
				text = L["mouseRingOnlyOnRightClick"],
				desc = L["mouseRingOnlyOnRightClickDesc"],
				func = function(v)
					addon.db["mouseRingOnlyOnRightClick"] = v
					if addon.Mouse.functions.refreshRingVisibility then addon.Mouse.functions.refreshRingVisibility() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
			},
			{
				var = "mouseRingCombatOverride",
				text = L["mouseRingCombatOverride"],
				desc = L["mouseRingCombatOverrideDesc"],
				func = function(v)
					addon.db["mouseRingCombatOverride"] = v
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
				children = {
					{
						var = "mouseRingCombatOverrideSize",
						text = L["mouseRingCombatOverrideSize"],
						desc = L["mouseRingCombatOverrideSizeDesc"],
						get = function() return addon.db and addon.db.mouseRingCombatOverrideSize or 70 end,
						set = function(v)
							addon.db["mouseRingCombatOverrideSize"] = v
							if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
						end,
						parentCheck = function()
							return addon.SettingsLayout.elements["mouseRingEnabled"]
								and addon.SettingsLayout.elements["mouseRingEnabled"].setting
								and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
								and addon.SettingsLayout.elements["mouseRingCombatOverride"]
								and addon.SettingsLayout.elements["mouseRingCombatOverride"].setting
								and addon.SettingsLayout.elements["mouseRingCombatOverride"].setting:GetValue() == true
						end,
						min = 20,
						max = 200,
						step = 1,
						parent = true,
						default = 70,
						sType = "slider",
						parentSection = expandable,
					},
					{
						var = "mouseRingCombatOverrideColor",
						text = L["mouseRingCombatOverrideColor"],
						desc = L["mouseRingCombatOverrideColorDesc"],
						parentCheck = function()
							return addon.SettingsLayout.elements["mouseRingEnabled"]
								and addon.SettingsLayout.elements["mouseRingEnabled"].setting
								and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
								and addon.SettingsLayout.elements["mouseRingCombatOverride"]
								and addon.SettingsLayout.elements["mouseRingCombatOverride"].setting
								and addon.SettingsLayout.elements["mouseRingCombatOverride"].setting:GetValue() == true
						end,
						callback = function(r, g, b, a)
							if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
						end,
						parent = true,
						hasOpacity = true,
						sType = "colorpicker",
						parentSection = expandable,
					},
				},
			},
			{
				var = "mouseRingCombatOverlay",
				text = L["mouseRingCombatOverlay"],
				desc = L["mouseRingCombatOverlayDesc"],
				func = function(v)
					addon.db["mouseRingCombatOverlay"] = v
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
				children = {
					{
						var = "mouseRingCombatOverlaySize",
						text = L["mouseRingCombatOverlaySize"],
						desc = L["mouseRingCombatOverlaySizeDesc"],
						get = function() return addon.db and addon.db.mouseRingCombatOverlaySize or 90 end,
						set = function(v)
							addon.db["mouseRingCombatOverlaySize"] = v
							if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
						end,
						parentCheck = function()
							return addon.SettingsLayout.elements["mouseRingEnabled"]
								and addon.SettingsLayout.elements["mouseRingEnabled"].setting
								and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
								and addon.SettingsLayout.elements["mouseRingCombatOverlay"]
								and addon.SettingsLayout.elements["mouseRingCombatOverlay"].setting
								and addon.SettingsLayout.elements["mouseRingCombatOverlay"].setting:GetValue() == true
						end,
						min = 20,
						max = 240,
						step = 1,
						parent = true,
						default = 90,
						sType = "slider",
						parentSection = expandable,
					},
					{
						var = "mouseRingCombatOverlayColor",
						text = L["mouseRingCombatOverlayColor"],
						desc = L["mouseRingCombatOverlayColorDesc"],
						parentCheck = function()
							return addon.SettingsLayout.elements["mouseRingEnabled"]
								and addon.SettingsLayout.elements["mouseRingEnabled"].setting
								and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
								and addon.SettingsLayout.elements["mouseRingCombatOverlay"]
								and addon.SettingsLayout.elements["mouseRingCombatOverlay"].setting
								and addon.SettingsLayout.elements["mouseRingCombatOverlay"].setting:GetValue() == true
						end,
						callback = function(r, g, b, a)
							if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
						end,
						parent = true,
						hasOpacity = true,
						sType = "colorpicker",
						parentSection = expandable,
					},
				},
			},
			{

				var = "mouseRingUseClassColor",
				text = L["mouseRingUseClassColor"],
				desc = L["mouseRingUseClassColorDesc"],
				func = function(v)
					addon.db["mouseRingUseClassColor"] = v
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				notify = "mouseRingEnabled",
				parentSection = expandable,
			},
			{
				var = "mouseRingColor",
				text = L["mouseRingColorLabel"] or L["Ring Color"],
				desc = L["mouseRingColorDesc"],
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
						and addon.SettingsLayout.elements["mouseRingUseClassColor"]
						and addon.SettingsLayout.elements["mouseRingUseClassColor"].setting
						and addon.SettingsLayout.elements["mouseRingUseClassColor"].setting:GetValue() == false
				end,
				callback = function(r, g, b, a)
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parent = true,
				default = false,
				hasOpacity = true,
				sType = "colorpicker",
				parentSection = expandable,
			},
			{
				var = "mouseRingClassColorAlpha",
				text = _G.OPACITY or "Opacity",
				desc = L["mouseRingClassColorAlphaDesc"],
				get = function()
					local color = addon.db and addon.db["mouseRingColor"]
					if color and color.a ~= nil then return color.a end
					return 1
				end,
				set = function(v)
					addon.db["mouseRingColor"] = addon.db["mouseRingColor"] or { r = 1, g = 1, b = 1, a = 1 }
					addon.db["mouseRingColor"].a = v
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseRingEnabled"]
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting
						and addon.SettingsLayout.elements["mouseRingEnabled"].setting:GetValue() == true
						and addon.SettingsLayout.elements["mouseRingUseClassColor"]
						and addon.SettingsLayout.elements["mouseRingUseClassColor"].setting
						and addon.SettingsLayout.elements["mouseRingUseClassColor"].setting:GetValue() == true
				end,
				min = 0,
				max = 1,
				step = 0.05,
				parent = true,
				default = 1,
				sType = "slider",
				parentSection = expandable,
			},
			{
				text = "",
				sType = "hint",
				parentCheck = function() return isRingEnabledSetting() end,
				parentSection = expandable,
			},
			{
				list = {
					DOT = L["mouseRingProgressStyleDot"],
					RING = L["mouseRingProgressStyleRing"],
				},
				order = { "DOT", "RING" },
				text = L["mouseRingProgressStyle"],
				desc = L["mouseRingProgressStyleDesc"],
				get = function() return addon.db["mouseRingProgressStyle"] or "DOT" end,
				set = function(key)
					addon.db["mouseRingProgressStyle"] = key
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function() return isRingEnabledSetting() end,
				parent = true,
				default = "DOT",
				var = "mouseRingProgressStyle",
				type = Settings.VarType.String,
				sType = "dropdown",
				parentSection = expandable,
			},
			{
				var = "mouseRingProgressShowEdge",
				text = L["mouseRingProgressShowEdge"],
				desc = L["mouseRingProgressShowEdgeDesc"],
				func = function(v)
					addon.db["mouseRingProgressShowEdge"] = v
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function()
					return isRingEnabledSetting() and isRingSwipeStyleSetting() and (addon.db and (addon.db["mouseRingCastProgress"] == true or addon.db["mouseRingGCDProgress"] == true))
				end,
				parent = true,
				default = true,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
			},
			{
				var = "mouseRingProgressHideDuringSwipe",
				text = L["mouseRingProgressHideDuringSwipe"],
				desc = L["mouseRingProgressHideDuringSwipeDesc"],
				get = function() return addon.db and addon.db.mouseRingProgressHideDuringSwipe or 35 end,
				set = function(v)
					addon.db["mouseRingProgressHideDuringSwipe"] = v
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function()
					return isRingEnabledSetting() and isRingSwipeStyleSetting() and (addon.db and (addon.db["mouseRingCastProgress"] == true or addon.db["mouseRingGCDProgress"] == true))
				end,
				min = 0,
				max = 100,
				step = 1,
				parent = true,
				default = 35,
				sType = "slider",
				parentSection = expandable,
			},
			{
				text = "",
				sType = "hint",
				parentCheck = function() return isRingEnabledSetting() end,
				parentSection = expandable,
			},
			{
				var = "mouseRingCastProgress",
				text = L["mouseRingCastProgress"],
				desc = L["mouseRingCastProgressDesc"],
				func = function(v)
					addon.db["mouseRingCastProgress"] = v
					if addon.Mouse.functions.syncRingProgressState then addon.Mouse.functions.syncRingProgressState() end
					if addon.Mouse.functions.refreshRingVisibility then addon.Mouse.functions.refreshRingVisibility() end
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function() return isRingEnabledSetting() end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
			},
			{
				var = "mouseRingCastProgressShowOutsideCombat",
				text = L["mouseRingCastProgressShowOutsideCombat"],
				desc = L["mouseRingCastProgressShowOutsideCombatDesc"],
				func = function(v)
					addon.db["mouseRingCastProgressShowOutsideCombat"] = v and true or false
					if addon.Mouse.functions.refreshRingVisibility then addon.Mouse.functions.refreshRingVisibility() end
				end,
				parentCheck = function() return isCastProgressEnabledSetting() end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
			},
			{
				var = "mouseRingCastProgressColor",
				text = L["mouseRingCastProgressColor"],
				desc = L["mouseRingCastProgressColorDesc"],
				parentCheck = function() return isCastProgressEnabledSetting() end,
				callback = function(r, g, b, a)
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parent = true,
				hasOpacity = true,
				sType = "colorpicker",
				parentSection = expandable,
			},
			{
				text = "",
				sType = "hint",
				parentCheck = function() return isRingEnabledSetting() end,
				parentSection = expandable,
			},
			{
				var = "mouseRingGCDProgress",
				text = L["mouseRingGCDProgress"],
				desc = L["mouseRingGCDProgressDesc"],
				func = function(v)
					addon.db["mouseRingGCDProgress"] = v
					if addon.Mouse.functions.syncRingProgressState then addon.Mouse.functions.syncRingProgressState() end
					if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
				end,
				parentCheck = function() return isRingEnabledSetting() end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
				children = {
					{
						var = "mouseRingGCDProgressColor",
						text = L["mouseRingGCDProgressColor"],
						desc = L["mouseRingGCDProgressColorDesc"],
						parentCheck = function()
							return isRingEnabledSetting()
								and addon.SettingsLayout.elements["mouseRingGCDProgress"]
								and addon.SettingsLayout.elements["mouseRingGCDProgress"].setting
								and addon.SettingsLayout.elements["mouseRingGCDProgress"].setting:GetValue() == true
						end,
						callback = function(r, g, b, a)
							if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
						end,
						parent = true,
						hasOpacity = true,
						sType = "colorpicker",
						parentSection = expandable,
					},
					{
						list = {
							REMAINING = L["Deplete (remaining time)"],
							ELAPSED = L["Fill (elapsed time)"],
						},
						order = { "REMAINING", "ELAPSED" },
						text = L["mouseRingGCDProgressMode"],
						desc = L["mouseRingGCDProgressModeDesc"],
						get = function() return addon.db["mouseRingGCDProgressMode"] or "REMAINING" end,
						set = function(key)
							addon.db["mouseRingGCDProgressMode"] = key
							if addon.Mouse.functions.refreshRingStyle then addon.Mouse.functions.refreshRingStyle() end
						end,
						parentCheck = function()
							return isRingEnabledSetting()
								and addon.SettingsLayout.elements["mouseRingGCDProgress"]
								and addon.SettingsLayout.elements["mouseRingGCDProgress"].setting
								and addon.SettingsLayout.elements["mouseRingGCDProgress"].setting:GetValue() == true
						end,
						parent = true,
						default = "REMAINING",
						var = "mouseRingGCDProgressMode",
						type = Settings.VarType.String,
						sType = "dropdown",
						parentSection = expandable,
					},
				},
			},
		},
	},
}
addon.functions.SettingsCreateCheckboxes(cMouse, data)

local crosshairExpandable = addon.functions.SettingsCreateExpandableSection(cMouse, {
	name = L["mouseCrosshair"] or "Crosshair",
	configPageKey = "MouseCrosshair",
	modernCategory = "general",
	iconKey = "uiutilities",
	modernOnly = true,
	expanded = false,
	colorizeTitle = false,
})

addon.functions.SettingsCreateHeadline(cMouse, L["mouseCrosshair"], { parentSection = crosshairExpandable })
data = {
	{
		var = "mouseCrosshairEnabled",
		text = L["mouseCrosshairEnabled"],
		desc = L["mouseCrosshairEnabledDesc"],
		default = false,
		newTagID = "mouseCrosshairEnabled",
		func = function(v)
			addon.db["mouseCrosshairEnabled"] = v and true or false
			if addon.Mouse.functions.updateEventRegistrations then addon.Mouse.functions.updateEventRegistrations() end
			if addon.Mouse.functions.refreshCrosshairRangeCheck then addon.Mouse.functions.refreshCrosshairRangeCheck() end
			if addon.Mouse.functions.refreshCrosshairVisibility then addon.Mouse.functions.refreshCrosshairVisibility() end
		end,
		parentSection = crosshairExpandable,
		children = {
			{
				text = "|cffffd700" .. L["mouseCrosshairEditModeHint"] .. "|r",
				sType = "hint",
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseCrosshairEnabled"]
						and addon.SettingsLayout.elements["mouseCrosshairEnabled"].setting
						and addon.SettingsLayout.elements["mouseCrosshairEnabled"].setting:GetValue() == true
				end,
				parentSection = crosshairExpandable,
			},
		},
	},
}
addon.functions.SettingsCreateCheckboxes(cMouse, data)

addon.functions.SettingsCreateCheckboxes(cMouse, {
	{
		var = "mouseCrosshairMeleeRange",
		text = L["mouseCrosshairRangeIndicator"],
		default = false,
		func = function(value)
			addon.db["mouseCrosshairMeleeRange"] = value and true or false
			if addon.Mouse.functions.updateEventRegistrations then addon.Mouse.functions.updateEventRegistrations() end
			if addon.Mouse.functions.refreshCrosshairRangeCheck then addon.Mouse.functions.refreshCrosshairRangeCheck() end
		end,
		parentCheck = function()
			return addon.SettingsLayout.elements["mouseCrosshairEnabled"]
				and addon.SettingsLayout.elements["mouseCrosshairEnabled"].setting
				and addon.SettingsLayout.elements["mouseCrosshairEnabled"].setting:GetValue() == true
		end,
		parent = true,
		parentSection = crosshairExpandable,
	},
})

addon.functions.SettingsCreateHeadline(cMouse, L["mouseCrosshairRangeSpells"] or "Range-check spells by specialization", { parentSection = crosshairExpandable })
addon.functions.SettingsCreateCustom(cMouse, {
	var = "mouseCrosshairRangeSpellTable",
	text = L["mouseCrosshairRangeSpells"] or "Range-check spells by specialization",
	desc = L["mouseCrosshairRangeSpellsDesc"] or "Spell ID used for the range check. The spell must exist in the game client.",
	height = 900,
	getHeight = function() return 900 end,
	parentCheck = function() return addon.db and addon.db["mouseCrosshairEnabled"] == true end,
	parentSection = crosshairExpandable,
	render = function(parent)
		local specOptions = addon.Mouse.functions.GetCrosshairRangeSpecOptions and addon.Mouse.functions.GetCrosshairRangeSpecOptions() or {}
		local rowHeight, gap, columns = 30, 6, 2
		local columnWidth = math.max(260, ((parent:GetWidth() or 600) - gap) / columns)
		local classTexture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
		local function updateSpell(row, spellID)
			spellID = tonumber(spellID)
			local info = spellID and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
			local name = info and info.name or (spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)) or ""
			local texture = info and info.iconID or (spellID and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID))
			row.spellName:SetText(name ~= "" and name or "Unknown spell")
			if texture then row.spellIcon:SetTexture(texture); row.spellIcon:Show() else row.spellIcon:Hide() end
			row.spellHit.spellID = spellID and name ~= "" and spellID or nil
		end
		local groups = {}
		for index = 1, #specOptions do
			local spec = specOptions[index]
			local group = groups[#groups]
			if not group or group.classToken ~= spec.classToken then
				group = { classToken = spec.classToken, specs = {} }
				groups[#groups + 1] = group
			end
			group.specs[#group.specs + 1] = spec
		end
		local line = 0
		for groupIndex = 1, #groups do
			local group = groups[groupIndex]
			for specIndex = 1, #group.specs do
				local spec = group.specs[specIndex]
				local column = (specIndex - 1) % columns
				local rowLine = line + math.floor((specIndex - 1) / columns)
			local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
			row:SetSize(columnWidth, rowHeight)
			row:SetPoint("TOPLEFT", parent, "TOPLEFT", column * (columnWidth + gap), -rowLine * (rowHeight + gap))
			row.bg = row:CreateTexture(nil, "BACKGROUND")
			row.bg:SetAllPoints()
			row.bg:SetColorTexture(0.08, 0.09, 0.1, 0.85)
			row.classIcon = row:CreateTexture(nil, "ARTWORK")
			row.classIcon:SetSize(20, 20)
			row.classIcon:SetPoint("LEFT", 8, 0)
			local coords = spec.classToken and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[spec.classToken]
			if coords then row.classIcon:SetTexture(classTexture); row.classIcon:SetTexCoord(unpack(coords)) else row.classIcon:Hide() end
			row.specIcon = row:CreateTexture(nil, "ARTWORK")
			row.specIcon:SetSize(20, 20)
			row.specIcon:SetPoint("LEFT", row.classIcon, "RIGHT", 3, 0)
			if spec.specIcon then row.specIcon:SetTexture(spec.specIcon) else row.specIcon:Hide() end
			row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			row.label:SetPoint("LEFT", row.specIcon, "RIGHT", 5, 0)
			row.label:SetWidth(math.max(80, columnWidth * 0.30))
			row.label:SetJustifyH("LEFT")
			row.label:SetText(spec.specName or spec.label)
			row.spellIcon = row:CreateTexture(nil, "ARTWORK")
			row.spellIcon:SetSize(20, 20)
			row.spellIcon:SetPoint("RIGHT", row, "RIGHT", -104, 0)
			row.spellName = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			row.spellName:SetPoint("RIGHT", row.spellIcon, "LEFT", -5, 0)
			row.spellName:SetWidth(math.max(70, columnWidth * 0.22))
			row.spellName:SetJustifyH("RIGHT")
			row.spellHit = CreateFrame("Frame", nil, row)
			row.spellHit:SetSize(112, 24)
			row.spellHit:SetPoint("RIGHT", row, "RIGHT", -96, 0)
			row.spellHit:EnableMouse(true)
			row.spellHit:SetScript("OnEnter", function(self)
				if not self.spellID then return end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetSpellByID(self.spellID)
				GameTooltip:Show()
			end)
			row.spellHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
			row.input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
			row.input:SetSize(82, 22)
			row.input:SetPoint("RIGHT", row, "RIGHT", -8, 0)
			row.input:SetNumeric(true)
			row.input:SetAutoFocus(false)
			row.input:SetJustifyH("CENTER")
			local spellID = addon.Mouse.functions.GetCrosshairRangeSpellForSpec and addon.Mouse.functions.GetCrosshairRangeSpellForSpec(spec.value)
			row.input:SetText(spellID and tostring(spellID) or "")
			row.input:SetScript("OnEnterPressed", function(self)
				local value = self:GetText()
				local ok = addon.Mouse.functions.SetCrosshairRangeSpellForSpec and addon.Mouse.functions.SetCrosshairRangeSpellForSpec(spec.value, value)
				if ok then
					if addon.Mouse.functions.refreshCrosshairRangeCheck then addon.Mouse.functions.refreshCrosshairRangeCheck() end
					updateSpell(row, tonumber(value))
				else
					local current = addon.Mouse.functions.GetCrosshairRangeSpellForSpec and addon.Mouse.functions.GetCrosshairRangeSpellForSpec(spec.value)
					self:SetText(current and tostring(current) or "")
				end
				self:ClearFocus()
			end)
			row.input:SetScript("OnEscapePressed", function(self) self:SetText(spellID and tostring(spellID) or ""); self:ClearFocus() end)
			updateSpell(row, spellID)
			end
			line = line + math.ceil(#group.specs / columns) + 1
		end
	end,
})

addon.functions.SettingsCreateHeadline(cMouse, L["mouseTrail"], { parentSection = expandable })

data = {
	{
		var = "mouseTrailEnabled",
		text = L["mouseTrailEnabled"],
		desc = L["mouseTrailEnabledDesc"],
		func = function(v)
			addon.db["mouseTrailEnabled"] = v
			if addon.Mouse.functions.updateRunnerState then addon.Mouse.functions.updateRunnerState() end
		end,
		parentSection = expandable,
		children = {
			{

				var = "mouseTrailOnlyInCombat",
				text = L["mouseTrailOnlyInCombat"],
				desc = L["mouseTrailOnlyInCombatDesc"],
				func = function(v) addon.db["mouseTrailOnlyInCombat"] = v end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseTrailEnabled"]
						and addon.SettingsLayout.elements["mouseTrailEnabled"].setting
						and addon.SettingsLayout.elements["mouseTrailEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				parentSection = expandable,
			},
			{

				var = "mouseTrailUseClassColor",
				text = L["mouseTrailUseClassColor"],
				desc = L["mouseTrailUseClassColorDesc"],
				func = function(v)
					addon.db["mouseTrailUseClassColor"] = v
					if addon.Mouse.functions.refreshTrailStyle then addon.Mouse.functions.refreshTrailStyle() end
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseTrailEnabled"]
						and addon.SettingsLayout.elements["mouseTrailEnabled"].setting
						and addon.SettingsLayout.elements["mouseTrailEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = false,
				type = Settings.VarType.Boolean,
				sType = "checkbox",
				notify = "mouseTrailEnabled",
				parentSection = expandable,
			},
			{
				var = "mouseTrailColor",
				text = L["mouseTrailColorLabel"] or L["Trail Color"],
				desc = L["mouseTrailColorDesc"],
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseTrailEnabled"]
						and addon.SettingsLayout.elements["mouseTrailEnabled"].setting
						and addon.SettingsLayout.elements["mouseTrailEnabled"].setting:GetValue() == true
						and addon.SettingsLayout.elements["mouseTrailUseClassColor"]
						and addon.SettingsLayout.elements["mouseTrailUseClassColor"].setting
						and addon.SettingsLayout.elements["mouseTrailUseClassColor"].setting:GetValue() == false
				end,
				parent = true,
				default = false,
				callback = function(r, g, b, a)
					if addon.Mouse.functions.refreshTrailStyle then addon.Mouse.functions.refreshTrailStyle() end
				end,
				sType = "colorpicker",
				parentSection = expandable,
			},
			{
				list = { [1] = VIDEO_OPTIONS_LOW, [2] = VIDEO_OPTIONS_MEDIUM, [3] = VIDEO_OPTIONS_HIGH, [4] = VIDEO_OPTIONS_ULTRA, [5] = VIDEO_OPTIONS_ULTRA_HIGH },
				order = { 1, 2, 3, 4, 5 },
				text = L["mouseTrailDensity"],
				desc = L["mouseTrailDensityDesc"],
				richNote = {
					title = L["mouseTrailDensity"],
					blocks = {
						{ text = "|cff99e599" .. L["Trailinfo"] .. "|r" },
					},
				},
				get = function() return addon.db["mouseTrailDensity"] or 1 end,
				set = function(key)
					addon.db["mouseTrailDensity"] = key
					addon.Mouse.functions.applyPreset(addon.db["mouseTrailDensity"])
				end,
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseTrailEnabled"]
						and addon.SettingsLayout.elements["mouseTrailEnabled"].setting
						and addon.SettingsLayout.elements["mouseTrailEnabled"].setting:GetValue() == true
				end,
				parent = true,
				default = 1,
				var = "mouseTrailDensity",
				type = Settings.VarType.Number,
				sType = "dropdown",
				parentSection = expandable,
			},
		},
	},
}
table.sort(data[1].children, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cMouse, data)

----- REGION END

function addon.functions.initMouse() end

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
