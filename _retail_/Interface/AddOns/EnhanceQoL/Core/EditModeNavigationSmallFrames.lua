local _, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local Small = {}
addon.EditModeNavigationSmallFrames = Small

local supported = {
	lowAmmoReminder = true, unspentTalentReminder = true,
	actionTracker = true, combatText = true, mouseCrosshair = true, durabilityWarning = true,
	containerActionsButton = true, groupToolsHealerMana = true, groupToolsDeathAlert = true,
	groupToolsNoTarget = true, ["EnhanceQoL:FoodReminder"] = true, talentReminderActiveBuild = true,
	partyKeystoneDungeonIndicator = true,
}

local function globalFont() return addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__" end
local function globalStyle() return addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__" end
local function white() return { r = 1, g = 1, b = 1, a = 1 } end

-- Only these small, audited constructors use this adapter. Keep source callbacks
-- intact and attach navigation metadata before the normal Edit Mode preparation.
function Small.Prepare(id, settings, opts)
	if not supported[id] or not settings or settings._smallNavigationPrepared then return end
	settings._smallNavigationPrepared = true
	local types = addon.EditModeLib.SettingType
	local factory = opts and opts.settingsFactoryDefaults or {}
	local fields, names = {}, {}
	local function field(key, tab, label, default) fields[key] = { tab = tab, label = label, default = default } end
	local function name(key, tab, label, default) names[L[key] or key] = { tab = tab, label = label, default = default } end
	local function literal(label, tab, replacement, default) names[label] = { tab = tab, label = replacement, default = default } end
	local function position(x, y)
		field("anchorTarget", "position", nil, "UIParent")
		field("point", "position", nil, "CENTER")
		field("relativePoint", "position", nil, "CENTER")
		field("x", "position", L["Offset X"], x)
		field("y", "position", L["Offset Y"], y)
		name("Anchor point", "position", nil, "CENTER")
		name("Relative point", "position", nil, "CENTER")
		name("X Offset", "position", L["Offset X"], x)
		name("Y Offset", "position", L["Offset Y"], y)
	end
	local function text(fontSize, color)
		name("Font", "text", nil, globalFont())
		name("Font outline", "text", nil, globalStyle())
		literal(_G.FONT_SIZE or L["Font Size"], "text", nil, fontSize)
		name("Text color", "text", L["Color"], color)
	end
	position(0, 0)
	if id == "lowAmmoReminder" or id == "unspentTalentReminder" then
		position(0, id == "lowAmmoReminder" and 160 or 220)
		for key, default in pairs({ hunterOnly = true, threshold = 200, durability = 20, itemID = 0 }) do field(key, "behavior", nil, default) end
		for _, key in ipairs({ "fontSize", "fontFace", "fontStyle", "color", "alignment" }) do field(key, "text", nil, factory[key]) end
		for _, key in ipairs({ "width", "height", "scale", "strata" }) do field(key, "position", nil, factory[key]) end
	elseif id == "actionTracker" then
		for _, key in ipairs({ "maxIcons", "size", "spacing", "direction", "iconShape", "iconZoom" }) do field(key, "icon", nil, factory[key]) end
		for _, key in ipairs({ "fade", "showElapsed", "onlyInCombat", "showGCDGaps", "showInterruptedCasts" }) do field(key, "behavior", nil, factory[key]) end
		field("size", "icon", L["Size"], factory.iconSize)
		field("spacing", "icon", L["Spacing"], factory.spacing)
		field("direction", "icon", L["Growth direction"], factory.direction)
		field("iconZoom", "icon", L["Zoom"], factory.iconZoom)
		field("fade", "behavior", nil, factory.fadeDuration)
	elseif id == "combatText" then
		for _, key in ipairs({ "duration", "alwaysVisible", "alwaysVisibleMode" }) do field(key, "behavior", nil, factory[key]) end
		for _, key in ipairs({ "fontSize", "fontFace", "fontOutline", "enterText", "leaveText", "enterColor", "leaveColor" }) do field(key, "text", nil, factory[key]) end
	elseif id == "durabilityWarning" then
		position(0, 180)
		for _, key in ipairs({ "threshold", "blinkEnabled", "blinkRate" }) do field(key, "behavior", nil, factory[key]) end
		for _, key in ipairs({ "readyCheckEnabled", "readyCheckThreshold", "readyCheckDuration" }) do field(key, "ready", nil, factory[key]) end
		for _, key in ipairs({ "fontSize", "fontFace", "fontStyle", "color" }) do field(key, "text", nil, factory[key]) end
	elseif id == "containerActionsButton" then
		field("buttonSize", "icon", L["Size"], factory.buttonSize)
		field("iconZoom", "icon", L["Zoom"], factory.iconZoom)
		name("containerActionsAreaHeader", "behavior")
	elseif id == "mouseCrosshair" then
		name("mouseCrosshairCircle", "display", nil, false)
		name("mouseCrosshairHideCross", "display", nil, false)
		name("mouseCrosshairCircleDiameter", "display", nil, 80)
		name("mouseCrosshairCircleThickness", "display", nil, 2)
		name("mouseCrosshairCircleUseCustomColor", "display", nil, false)
		name("mouseCrosshairCircleColor", "display", nil, { r = 0.2, g = 1, b = 0.2, a = 1 })
		name("mouseCrosshairGap", "display", L["Center gap"], 0)
		name("mouseCrosshairThickness", "display", L["Thickness"], 4)
		name("mouseCrosshairLength", "display", L["Inner length"], 24)
		name("mouseCrosshairBorderSize", "display", L["Border size"], 4)
		name("mouseCrosshairAlpha", "display", L["Alpha"], 1)
		name("mouseCrosshairUseClassColor", "display", L["Use class color"], false)
		name("mouseCrosshairColor", "display", L["Color"], { r = 0.2, g = 1, b = 0.2, a = 1 })
		name("mouseCrosshairRangeIndicator", "range", nil, false)
		name("mouseCrosshairOutOfRangeColor", "range", nil, { r = 1, g = 0.2, b = 0.2, a = 1 })
		name("mouseCrosshairHideInLegacyRaidInstances", "visibility", nil, false)
		field("showWhen", "visibility")
	elseif id == "groupToolsHealerMana" then
		position(-100, 50)
		text(14, white())
		name("groupToolsHealerManaEnableDungeons", "behavior", nil, true)
		name("groupToolsHealerManaEnableRaids", "behavior", nil, false)
		name("groupToolsHealerManaGrowUpwards", "position", nil, false)
		name("groupToolsHealerManaShowName", "text", L["Show name"], true)
		name("classicReminderAlignment", "text", nil, "LEFT")
		name("Name max width", "text", nil, 0)
		name("Hide ellipsis", "text", nil, false)
		name("Frame strata", "position", L["Strata"], "MEDIUM")
	elseif id == "groupToolsDeathAlert" then
		position(0, 200)
		text(28, white())
		name("groupToolsDeathAlertShowText", "text", nil, true)
		name("groupToolsDisplayDuration", "text", nil, 2)
		name("Frame strata", "position", L["Strata"], "HIGH")
		name("groupToolsTTSVoice", "tts", nil, 0)
		name("groupToolsTTSVolume", "tts", nil, 50)
		name("groupToolsPlaySound", nil, nil, false)
		literal(_G.SOUND or "Sound", nil, nil, "")
		name("groupToolsPlayTTS", nil, nil, false)
		name("groupToolsTTSMessage", nil, nil, "")
	elseif id == "groupToolsNoTarget" then
		position(0, 25)
		text(18, { r = 0.769, g = 0.118, b = 0.227, a = 1 })
		name("groupToolsNoTargetShowText", "text", nil, true)
		name("groupToolsDisplayText", "text", nil, L["groupToolsNoTargetDefaultText"])
		name("Frame strata", "position", L["Strata"], "HIGH")
		name("groupToolsNoTargetDelay", "behavior", nil, 1)
		name("groupToolsNoTargetFriendly", "behavior", nil, false)
		name("groupToolsPlaySound", "behavior", nil, false)
		literal(_G.SOUND or "Sound", "behavior", nil, "")
	elseif id == "EnhanceQoL:FoodReminder" then
		name("mageFoodReminderSize", "icon", L["Scale"], 1)
		name("settingsIconShapeLabel", "icon", nil, "DEFAULT")
		name("Icon zoom", "icon", L["Zoom"], 0)
		name("mageFoodReminderJoinSound", "sound", nil, "__DEFAULT_SOUND__")
		name("mageFoodReminderLeaveSound", "sound", nil, "__DEFAULT_SOUND__")
	elseif id == "talentReminderActiveBuild" then
		name("Text Size", "display", _G.FONT_SIZE or L["Font Size"], 14)
		name("talentReminderShowActiveBuildDropdown", "display", L["Show when"], {})
	elseif id == "partyKeystoneDungeonIndicator" then
		position(360, 100)
		name("keystoneDungeonIndicatorShowHeader", "header", nil, true)
		name("mythicPlusTimerAlign", "layout", nil, "LEFT")
		name("Growth direction", "layout", nil, "DOWN")
		name("Vertical spacing", "layout", L["Spacing"], 2)
		literal(L["Name"] .. " - " .. L["X Offset"], "name", L["Offset X"], 0)
		literal(L["Name"] .. " - " .. L["Y Offset"], "name", L["Offset Y"], 0)
		name("Font", "font", nil, globalFont())
		name("Font outline", "font", nil, globalStyle())
		literal(L["Header"] .. " - " .. (_G.FONT_SIZE or L["Font Size"]), "header", _G.FONT_SIZE or L["Font Size"], 20)
		literal(L["Name"] .. " - " .. (_G.FONT_SIZE or L["Font Size"]), "name", _G.FONT_SIZE or L["Font Size"], 18)
		name("Use class color", "name", nil, true)
		name("keystoneDungeonIndicatorUseRarityColor", "level", nil, true)
		for _, key in ipairs({ "Header", "Name", "Level" }) do literal(L[key] .. " - " .. L["Text color"], key:lower(), L["Color"], white()) end
	end

	local tabs, result, headers = {}, {}, {}
	local labels = {
		position = L["Position"], icon = L["Icon"], display = L["Display"], behavior = L["Behavior"],
		text = L["Text"], ready = L["Ready check"], border = L["Border"], glow = L["Glow effect"],
		range = L["CooldownPanelRangeIndicator"], visibility = L["Visibility"], sound = _G.SOUND or "Sound",
		tts = _G.TEXT_TO_SPEECH or L["groupToolsPlayTTS"], layout = L["Layout"], header = L["Header"], name = L["Name"], level = L["Level"], font = L["Font"],
	}
	for _, data in ipairs(settings) do if data.kind == types.Collapsible then headers[data.id] = data end end
	for _, data in ipairs(settings) do
		if data.kind ~= types.Collapsible and (data.kind ~= types.Divider or (data.parentId and data.name and data.name ~= "")) then
			local key = data.navigationField or data.field or ""
			local meta = fields[key] or names[data.name] or {}
			local tab = meta.tab
			local default = meta.default
			if key:find("^dynamicAnchor") then tab = "position" end
			if key:find("^border") then
				tab, default = "border", factory[key]
				local compact = { borderTexture = L["Texture"], borderSize = L["Size"], borderOffset = L["Offset"], borderColor = L["Color"] }
				meta.label = compact[key]
			elseif key:find("^glow") then
				tab, default = "glow", factory[key]
				local compact = { glowStyle = L["Style"], glowColor = L["Color"], glowInset = L["Inset"], glowThickness = L["Thickness"] }
				meta.label = compact[key]
			end
			if id == "groupToolsDeathAlert" and data.parentId and data.parentId:find("^groupToolsDeathAlert") then
				tab = data.parentId
				labels[tab] = headers[tab] and headers[tab].name or tab
				if default == nil and data.kind == types.Checkbox then default, meta.label = false, L["EditModeNavDisableText"] end
			end
			tab = tab or "display"
			if not tabs[tab] then tabs[tab] = {}; result[#result + 1] = tab end
			data.navigationId = data.navigationId or key ~= "" and key or data.name
			data.searchTags = (data.searchTags or "") .. " " .. (data.name or "")
			if meta.label then data.name = meta.label end
			local oldParent, previousHint = data.parentId, data.navigationHint
			data.parentId = "small:" .. tab
			if previousHint then
				data.navigationHint = function(...)
					local target, section, targetTab, explanation = previousHint(...)
					if not targetTab or targetTab == oldParent then targetTab = data.parentId end
					return target, section, targetTab, explanation
				end
			end
			if default ~= nil then data.default = default end
			-- Remaining defaults in these constructors are literals or their local
			-- factory table. Dynamic anchor metadata owns its separate reset path.
			if not key:find("^dynamicAnchor") and data.default ~= nil and not data.navigationReset then data.navigationDefaultVerified = true end
			if id == "mouseCrosshair" and key == "showWhen" and data.isShown and not data.isShown() then data.navigationSearchExcluded = true end
			tabs[tab][#tabs[tab] + 1] = data
		end
	end
	for index = #settings, 1, -1 do settings[index] = nil end
	for _, tab in ipairs(result) do
		settings[#settings + 1] = { kind = types.Collapsible, id = "small:" .. tab, name = labels[tab] or L["General"], defaultCollapsed = false }
		for _, data in ipairs(tabs[tab]) do settings[#settings + 1] = data end
	end
end

function Small.Get(id)
	if not supported[id] then return nil end
	local function groups(...)
		local result = { ... }
		for index, value in ipairs(result) do result[index] = "small:" .. value end
		return result
	end
	local categories
	if id == "groupToolsDeathAlert" then
		categories = {
			{ id = "frame", name = L["Frame"], groups = groups("position", "text") },
			{ id = "behavior", name = L["Behavior"], groups = groups("groupToolsDeathAlertTANK", "groupToolsDeathAlertHEALER", "groupToolsDeathAlertDAMAGER") },
		}
	elseif id == "partyKeystoneDungeonIndicator" then
		categories = {
			{ id = "frame", name = L["Frame"], groups = groups("position", "layout") },
			{ id = "text", name = L["Text"], groups = groups("font", "header", "name", "level") },
		}
	else
		categories = { { id = "settings", name = L["Settings"], groups = groups("position", "icon", "display", "text", "behavior", "ready", "border", "glow", "range", "visibility", "sound") } }
	end
	return {
		categories = categories,
		canReset = function(tab)
			for _, data in ipairs(tab.settings) do
				if data.kind ~= addon.EditModeLib.SettingType.Divider and not data.navigationSearchExcluded and not data.navigationResetExcluded and not data.navigationReset and not data.navigationDefaultVerified then return false end
			end
			return true
		end,
	}
end
