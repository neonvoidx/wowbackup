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

addon.functions.SettingsCreateHeadline(cMouse, L["mouseCrosshair"], { parentSection = expandable })
data = {
	{
		var = "mouseCrosshairEnabled",
		text = L["mouseCrosshairEnabled"],
		desc = L["mouseCrosshairEnabledDesc"],
		default = false,
		func = function(v)
			addon.db["mouseCrosshairEnabled"] = v and true or false
			if addon.Mouse.functions.updateEventRegistrations then addon.Mouse.functions.updateEventRegistrations() end
			if addon.Mouse.functions.refreshCrosshairVisibility then addon.Mouse.functions.refreshCrosshairVisibility() end
		end,
		parentSection = expandable,
		children = {
			{
				text = "|cffffd700" .. L["mouseCrosshairEditModeHint"] .. "|r",
				sType = "hint",
				parentCheck = function()
					return addon.SettingsLayout.elements["mouseCrosshairEnabled"]
						and addon.SettingsLayout.elements["mouseCrosshairEnabled"].setting
						and addon.SettingsLayout.elements["mouseCrosshairEnabled"].setting:GetValue() == true
				end,
				parentSection = expandable,
			},
		},
	},
}
addon.functions.SettingsCreateCheckboxes(cMouse, data)

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
