local addonName, addon = ...
local R = addon.RangeDisplay
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function R:BuildSettings()
	local T = addon.EditModeLib.SettingType
	local settings = {}
	local function group(id, name)
		settings[#settings + 1] = { id = id, name = name, kind = T.Collapsible }
	end
	local function row(field, name, kind, parent, extra)
		local control = extra or {}
		control.field, control.navigationField = field, field
		control.name, control.kind, control.parentId = name, kind, parent
		control.default = R.defaults[field]
		control.get = function() return R:Value(field) end
		control.set = function(_, value)
			if type(value) == "table" then value = CopyTable(value) end
			R:SetSetting(field, value)
		end
		settings[#settings + 1] = control
		return control
	end
	local function slider(field, name, parent, minimum, maximum, step)
		return row(field, name, T.Slider, parent, { minValue = minimum, maxValue = maximum, valueStep = step or 1, allowInput = true })
	end
	local function dropdown(field, name, parent, options)
		return row(field, name, T.Dropdown, parent, { height = 220, generator = function(_, root)
			for _, option in ipairs(options()) do
				root:CreateRadio(option.label, function() return R:Value(field) == option.value end,
					function() R:SetSetting(field, option.value) end)
			end
		end })
	end
	local function mediaOptions(kind)
		return function()
			local options = { { value = "", label = _G.DEFAULT } }
			local media = LibStub("LibSharedMedia-3.0", true)
			if media then
				for _, name in ipairs(media:List(kind)) do options[#options + 1] = { value = name, label = name } end
			end
			return options
		end
	end
	group("position", L["Position"])
	local function points() return addon.SharedAnchors:GetAnchorPointOptions() end
	dropdown("point", L["Anchor point"], "position", points)
	dropdown("relativePoint", L["Relative point"], "position", points)
	slider("x", L["Offset X"], "position", -2000, 2000)
	slider("y", L["Offset Y"], "position", -2000, 2000)
	slider("width", L["Width"], "position", 60, 600)
	slider("height", L["Height"], "position", 20, 200)
	group("text", L["Font"])
	dropdown("font", L["Font"], "text", function()
		local options = { { value = R.defaults.font, label = addon.functions.GetGlobalFontConfigLabel() } }
		local media = LibStub("LibSharedMedia-3.0", true)
		if media then
			for _, name in ipairs(media:List("font")) do options[#options + 1] = { value = media:Fetch("font", name), label = name } end
		end
		return options
	end)
	slider("fontSize", _G.FONT_SIZE, "text", 8, 96)
	dropdown("fontStyle", L["Font outline"], "text", function() return addon.functions.GetFontStyleOptionList(true) end)
	row("color", L["Text color"], T.Color, "text", { hasOpacity = true })
	group("appearance", L["Style"])
	slider("alpha", L["Alpha"], "appearance", 0.1, 1, 0.05)
	dropdown("strata", L["Strata"], "appearance", function()
		local options = {}
		for _, value in ipairs({ "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG" }) do options[#options + 1] = { value = value, label = value } end
		return options
	end)
	group("background", L["Background"])
	row("background", L["Background"], T.Checkbox, "background")
	row("backgroundUseCustomTexture", L["damageMeterBackdropUseCustomTexture"], T.Checkbox, "background", { isEnabled = function() return R:Value("background") end })
	row("backgroundCustomTexture", L["damageMeterBackdropCustomTexture"], T.Input, "background", {
		maxChars = 160, tooltip = L["damageMeterHeaderBackgroundCustomTextureDesc"],
		isEnabled = function() return R:Value("background") and R:Value("backgroundUseCustomTexture") end,
	})
	dropdown("backgroundTexture", L["Background texture"], "background", mediaOptions("statusbar")).isEnabled = function() return R:Value("background") and not R:Value("backgroundUseCustomTexture") end
	row("backgroundColor", L["Background color"], T.Color, "background", { hasOpacity = true, isEnabled = function() return R:Value("background") end })
	slider("backgroundWidthOffset", L["DataPanelBackgroundSizeOffsetX"], "background", -600, 600).isEnabled = function() return R:Value("background") end
	slider("backgroundHeightOffset", L["DataPanelBackgroundSizeOffsetY"], "background", -200, 200).isEnabled = function() return R:Value("background") end
	group("border", L["Border"])
	row("border", L["Border"], T.Checkbox, "border")
	dropdown("borderTexture", L["Border texture"], "border", mediaOptions("border")).isEnabled = function() return R:Value("border") end
	slider("borderSize", L["Border size"], "border", 1, 8).isEnabled = function() return R:Value("border") end
	row("borderColor", L["Border color"], T.Color, "border", { hasOpacity = true, isEnabled = function() return R:Value("border") end })
	slider("borderWidthOffset", L["DataPanelBackgroundSizeOffsetX"], "border", -600, 600).isEnabled = function() return R:Value("border") end
	slider("borderHeightOffset", L["DataPanelBackgroundSizeOffsetY"], "border", -200, 200).isEnabled = function() return R:Value("border") end
	group("visibility", L["Visibility"])
	row("onlyCombat", L["rangeDisplayOnlyCombat"], T.Checkbox, "visibility")
	addon.EditModeNavigationDefaults.Prepare(settings, R.defaults, true)
	return settings
end

function R:RegisterEditor()
	self.registered = true
	addon.EditMode:RegisterFrame(self.id, {
		frame = self.frame, title = L["rangeDisplayName"], managerCategory = "trackers",
		layoutDefaults = CopyTable(self.defaults), settings = self:BuildSettings(),
		settingsNavigation = { categories = { { id = "display", name = L["rangeDisplayName"], groups = { "position", "text", "appearance", "background", "border", "visibility" } } },
			tabNames = { position = L["Position"], text = L["Font"], appearance = L["Style"], background = L["Background"], border = L["Border"], visibility = L["Visibility"] } },
		isEnabled = function() return R.active end,
		onApply = function() R:ApplyStyle(); R:RefreshTarget() end,
		onEnter = function() R.preview = true; R:RefreshTarget() end,
		onExit = function() R.preview = false; R:RefreshTarget() end,
		manageVisibilityOutsideEditMode = false,
	})
	self.preview = addon.EditMode:IsInEditMode()
end
