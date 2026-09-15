local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = _G.LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local QC = addon.QuickCast
local app = addon.ConfigApp

if not (app and QC and QC.Editor) then return end

local function openEditor()
	local frame = QC.Editor:Open()
	if frame and addon.functions and addon.functions.HideConfigCenterUntilFrameHidden then
		addon.functions.HideConfigCenterUntilFrameHidden(frame)
	end
end

app:RegisterPage({
	id = "interface.quickactions",
	category = "interface",
	title = L["QuickCast"] or "QuickActions",
	description = L["QuickCastDescription"]
		or "Create configurable menus for frequently used actions.",
	iconAtlas = "common-icon-undo",
	order = 85,
	newTagID = "QuickActionsPage",
})

app:RegisterControl("interface.quickactions", {
	id = "quickactions.activationMode",
	type = "dropdown",
	label = L["QuickCastActivationMode"] or "Activation mode",
	description = L["QuickCastActivationModeDesc"]
		or "Choose whether the ring stays open while the hotkey is held or until the hotkey is pressed again or an action is used.",
	list = {
		[QC.ACTIVATION_MODE_HOLD] = L["QuickCastActivationModeHold"] or "Hold and release",
		[QC.ACTIVATION_MODE_TOGGLE] = L["QuickCastActivationModeToggle"] or "Press to toggle",
	},
	orderList = { QC.ACTIVATION_MODE_HOLD, QC.ACTIVATION_MODE_TOGGLE },
	getValue = function() return QC:GetActivationMode() end,
	setValue = function(value) QC:SetActivationMode(value) end,
	default = QC.DEFAULT_ACTIVATION_MODE,
	newTagID = "QuickActionsActivationMode",
	order = 10,
})

app:RegisterControl("interface.quickactions", {
	id = "quickactions.animationStyle",
	type = "dropdown",
	label = L["QuickCastAnimationStyle"] or "Animation style",
	description = L["QuickCastAnimationStyleDesc"] or "Choose how QuickActions menus animate.",
	list = {
		NONE = _G.NONE or "None",
		REDUCED = L["QuickCastAnimationReduced"] or "Reduced",
		DYNAMIC = L["QuickCastAnimationDynamic"] or "Dynamic",
	},
	orderList = { "NONE", "REDUCED", "DYNAMIC" },
	getValue = function() return QC:GetAnimationStyle() end,
	setValue = function(value) QC:SetAnimationStyle(value) end,
	default = QC.DEFAULT_ANIMATION_STYLE,
	newTagID = "QuickActionsAnimationStyle",
	order = 20,
})

app:RegisterControl("interface.quickactions", {
	id = "quickactions.selectionIndicator",
	type = "dropdown",
	label = L["QuickCastSelectionIndicator"] or "Selection indicator",
	description = L["QuickCastSelectionIndicatorDesc"] or "Choose how the selected action is marked.",
	list = {
		ARROWS = L["QuickCastSelectionIndicatorArrows"] or "Arrows",
		LINES = L["QuickCastSelectionIndicatorLines"] or "Lines",
		NONE = _G.NONE or "None",
	},
	orderList = { "ARROWS", "LINES", "NONE" },
	getValue = function() return QC:GetSelectionIndicator() end,
	setValue = function(value) QC:SetSelectionIndicator(value) end,
	default = QC.DEFAULT_SELECTION_INDICATOR,
	newTagID = "QuickActionsSelectionIndicator",
	refreshOnChange = true,
	order = 30,
})

app:RegisterControl("interface.quickactions", {
	id = "quickactions.selectionIndicatorColor",
	type = "colorpicker",
	label = L["QuickCastSelectionIndicatorColor"] or "Selection indicator color",
	description = L["QuickCastSelectionIndicatorColorDesc"] or "Choose the color and opacity used by the arrows or lines.",
	hasOpacity = true,
	default = QC.DEFAULT_SELECTION_INDICATOR_COLOR,
	getValue = function() return QC:GetSelectionIndicatorColor() end,
	setValue = function(value)
		if type(value) ~= "table" then return end
		QC:SetSelectionIndicatorColor(value[1] or value.r, value[2] or value.g, value[3] or value.b, value[4] or value.a)
	end,
	getColor = function()
		local color = QC:GetSelectionIndicatorColor()
		return color[1], color[2], color[3], color[4]
	end,
	setColor = function(_, r, g, b, a) QC:SetSelectionIndicatorColor(r, g, b, a) end,
	getDefaultColor = function()
		local color = QC.DEFAULT_SELECTION_INDICATOR_COLOR
		return color[1], color[2], color[3], color[4]
	end,
	isEnabled = function() return QC:GetSelectionIndicator() ~= QC.SELECTION_INDICATOR_NONE end,
	newTagID = "QuickActionsSelectionIndicatorColor",
	order = 40,
})

app:RegisterControl("interface.quickactions", {
	id = "quickactions.selectionHighlight",
	type = "toggle",
	label = L["QuickCastSelectionHighlight"] or "Tint selected icon",
	description = L["QuickCastSelectionHighlightDesc"] or "Adds a colored overlay to the selected icon.",
	getValue = function() return QC:IsSelectionOverlayEnabled() end,
	setValue = function(value) QC:SetSelectionOverlayEnabled(value) end,
	default = QC.DEFAULT_SELECTION_OVERLAY_ENABLED,
	newTagID = "QuickActionsSelectionHighlight",
	order = 50,
})

app:RegisterControl("interface.quickactions", {
	id = "quickactions.selectionIconScale",
	type = "slider",
	label = L["QuickCastSelectionIconScale"] or "Selected icon size",
	description = L["QuickCastSelectionIconScaleDesc"] or "Sets the icon size while selected. 100% keeps the normal size.",
	min = QC.MIN_SELECTION_ICON_SCALE * 100,
	max = QC.MAX_SELECTION_ICON_SCALE * 100,
	step = 1,
	suffix = "%",
	getValue = function() return math.floor(QC:GetSelectionIconScale() * 100 + 0.5) end,
	setValue = function(value)
		QC:SetSelectionIconScale((tonumber(value) or QC.DEFAULT_SELECTION_ICON_SCALE * 100) / 100)
	end,
	default = math.floor(QC.DEFAULT_SELECTION_ICON_SCALE * 100 + 0.5),
	newTagID = "QuickActionsSelectionIconScale",
	order = 60,
})

app:RegisterControl("interface.quickactions", {
	id = "quickactions.unselectedIconAlpha",
	type = "slider",
	label = L["QuickCastUnselectedIconAlpha"] or "Unselected icon opacity",
	description = L["QuickCastUnselectedIconAlphaDesc"]
		or "Sets the opacity of other icons while an action is selected.",
	min = 0,
	max = 100,
	step = 1,
	suffix = "%",
	getValue = function() return math.floor(QC:GetUnselectedIconAlpha() * 100 + 0.5) end,
	setValue = function(value)
		QC:SetUnselectedIconAlpha((tonumber(value) or QC.DEFAULT_UNSELECTED_ICON_ALPHA * 100) / 100)
	end,
	default = math.floor(QC.DEFAULT_UNSELECTED_ICON_ALPHA * 100 + 0.5),
	newTagID = "QuickActionsUnselectedIconAlpha",
	order = 70,
})

app:RegisterControl("interface.quickactions", {
	id = "quickactions.openEditor",
	type = "button",
	label = L["QuickCastOpenEditor"] or "Open QuickActions editor",
	buttonText = L["QuickCastOpenEditor"] or "Open QuickActions editor",
	onClick = openEditor,
	order = 80,
})
