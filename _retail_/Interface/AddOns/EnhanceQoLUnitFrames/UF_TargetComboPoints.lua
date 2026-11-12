local addon = _G.EnhanceQoL
if not (addon and addon.variables and (addon.variables.isForever or addon.variables.isTBC)) then return end
local UF = addon.Aura and addon.Aura.UF
if not UF then return end
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local C = {}
UF.TargetComboPoints = C
C.defaults = { enabled = true, style = "BLIZZARD", strata = "", frameLevelOffset = 8, anchor = "TOP", x = 0, y = 12, scale = 1, spacing = 4, width = 120, height = 10, texture = "SOLID", color = { 1, 0.8, 0.1, 1 }, background = { 0.1, 0.1, 0.1, 0.7 } }
C.strata = { BACKGROUND = true, LOW = true, MEDIUM = true, HIGH = true, DIALOG = true, FULLSCREEN = true, FULLSCREEN_DIALOG = true, TOOLTIP = true }
C.count = 5
C.visuals = {
	ROGUE = { active = "BGActive", inactive = "BGInactive", icon = "IconUncharged", slash = "SlashFBUncharged", effects = { "BGGlow", "FXUncharged", "FrameGlow" }, template = "EQOLTargetComboRogueTemplate" },
	DRUID = { active = "BG_Active", inactive = "BG_Inactive", icon = "Point_Icon", slash = "FB_Slash", effects = { "BG_Glow", "Point_Deplete", "FX_RingGlow", "Smoke" }, template = "EQOLTargetComboDruidTemplate" },
}

function C.GetClass() return addon.variables.unitClass or select(2, UnitClass("player")) end
function C.IsPreview() return addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() == true end
function C.Option(key)
	local cfg = C.cfg and C.cfg.comboPoints
	local value
	if type(cfg) == "table" then value = cfg[key] end
	if value == nil then return C.defaults[key] end
	return value
end
function C.Number(key, minimum, maximum)
	return math.max(minimum, math.min(maximum, tonumber(C.Option(key)) or C.defaults[key]))
end

function C.ResetPoint(point, full)
	local visual = C.visuals[C.class]
	point.activateAnim:Stop()
	point.deactivateAnim:Stop()
	point[visual.active]:SetAlpha(full and 1 or 0)
	point[visual.inactive]:SetAlpha(full and 0 or 1)
	point[visual.icon]:SetAlpha(full and 1 or 0)
	point[visual.slash]:SetAlpha(0)
	for _, key in ipairs(visual.effects) do point[key]:SetAlpha(0) end
	point.full = full
end

function C.UpdatePoint(point, full, animate)
	if point.full == full then return end
	local previous = point.full
	C.ResetPoint(point, full)
	if not animate or previous == nil then return end
	local visual = C.visuals[C.class]
	if full then
		point[visual.slash]:SetAlpha(1)
		point.activateAnim:Play()
	else
		point.deactivateAnim:Play()
	end
end

function C.EnsureFrames()
	if C.frame or not (C.state and C.state.frame) or InCombatLockdown() then return end
	C.class = C.GetClass()
	local visual = C.visuals[C.class]
	if not visual then return end
	local frame = CreateFrame("Frame", nil, C.state.frame)
	C.frame = frame
	frame:SetAlpha(0)
	frame:EnableMouse(false)
	C.points, C.bars = {}, {}
	for i = 1, C.count do
		local point = CreateFrame("Frame", nil, frame, visual.template)
		point:EnableMouse(false)
		point.activateAnim:SetScript("OnFinished", function() C.ResetPoint(point, point.full) end)
		point.deactivateAnim:SetScript("OnFinished", function() C.ResetPoint(point, point.full) end)
		C.ResetPoint(point, false)
		C.points[i] = point
		local bar = CreateFrame("StatusBar", nil, frame)
		bar:EnableMouse(false)
		bar:SetMinMaxValues(0, 1)
		bar.background = bar:CreateTexture(nil, "BACKGROUND")
		bar.background:SetAllPoints()
		C.bars[i] = bar
	end
	frame:SetScript("OnShow", function() C.Refresh(true) end)
	frame:SetScript("OnHide", function()
		C.visible = false
		C.lastPoints = nil
		for _, point in ipairs(C.points) do C.ResetPoint(point, false) end
	end)
end

function C.Layout()
	C.EnsureFrames()
	if not C.frame then return end
	local frame = C.frame
	local anchor = C.Option("anchor") == "BOTTOM" and "BOTTOM" or "TOP"
	local spacing = C.Number("spacing", 0, 20)
	local barStyle = C.Option("style") == "BAR"
	local width = barStyle and C.Number("width", 40, 600) or C.count * 20 + (C.count - 1) * spacing
	-- Keep every segment positive even at the smallest width and largest gap.
	if barStyle then spacing = math.min(spacing, (width - C.count) / (C.count - 1)) end
	local height = barStyle and C.Number("height", 2, 40) or 20
	local scale = C.Number("scale", 0.25, 3)
	local offsetX = C.Number("x", -3000, 3000)
	local offsetY = C.Number("y", -3000, 3000) + UF.GetVirtualUnitFramePointOffsetY(C.state.frame, anchor)
	local strata = C.Option("strata")
	frame:SetFrameStrata(C.strata[strata] and strata or C.state.frame:GetFrameStrata())
	frame:SetFrameLevel(C.state.frame:GetFrameLevel() + math.floor(C.Number("frameLevelOffset", 0, 50)))
	frame:SetScale(scale)
	frame:ClearAllPoints()
	-- Keep the configured offsets in target-frame units while scaling the artwork.
	frame:SetPoint(anchor == "TOP" and "BOTTOM" or "TOP", C.state.frame, anchor, offsetX / scale, offsetY / scale)
	frame:SetSize(width, height)
	local texture = addon.Aura.UFHelper.resolveTexture(C.Option("texture"))
	local color, background = C.Option("color"), C.Option("background")
	for i = 1, C.count do
		local point, bar = C.points[i], C.bars[i]
		C.ResetPoint(point, false)
		point:ClearAllPoints()
		point:SetPoint("LEFT", frame, "LEFT", (i - 1) * (20 + spacing), 0)
		point:SetAlpha(barStyle and 0 or 1)
		bar:ClearAllPoints()
		local segmentWidth = (width - spacing * (C.count - 1)) / C.count
		bar:SetPoint("LEFT", frame, "LEFT", (i - 1) * (segmentWidth + spacing), 0)
		bar:SetSize(segmentWidth, height)
		bar:SetStatusBarTexture(texture)
		bar:SetStatusBarColor(unpack(color))
		bar.background:SetColorTexture(unpack(background))
		bar:SetAlpha(barStyle and 1 or 0)
	end
	C.visible = false
	C.lastPoints = nil
end

function C.Refresh(reset)
	if not C.frame then return end
	local enabled = C.cfg and C.cfg.enabled == true and C.Option("enabled") == true
	local sample = enabled and C.IsPreview()
	local valid = enabled and C.visuals[C.GetClass()] and (sample or UnitExists("target"))
	if valid and not sample and C.GetClass() == "DRUID" then valid = UnitPowerType("player") == Enum.PowerType.Energy end
	local points = valid and (sample and 3 or GetComboPoints("player", "target")) or 0
	points = math.max(0, math.min(C.count, points or 0))
	local visible = valid and points > 0
	if not reset and C.lastPoints == points and C.lastValid == valid and C.lastSample == sample then return end
	C.lastPoints, C.lastValid, C.lastSample = points, valid, sample
	local animate = not reset and valid and C.frame:IsShown() and not sample and C.Option("style") ~= "BAR"
	C.generation = (C.generation or 0) + 1
	local generation = C.generation
	for i = 1, C.count do
		if reset or not valid then C.ResetPoint(C.points[i], i <= points) else C.UpdatePoint(C.points[i], i <= points, animate) end
		C.bars[i]:SetValue(i <= points and 1 or 0)
	end
	-- Let the spend animation finish before hiding an empty row.
	if not visible and animate and valid then
		C_Timer.After(0.7, function()
			if C.generation == generation then C.frame:SetAlpha(0) end
		end)
	else
		C.frame:SetAlpha(visible and 1 or 0)
	end
	C.visible = visible == true
end

function C.OnEvent(_, event, unit, powerToken)
	if event == "PLAYER_REGEN_ENABLED" then C.Apply(C.cfg, C.state); return end
	if event == "UNIT_POWER_FREQUENT" and (unit ~= "player" or powerToken ~= "COMBO_POINTS") then return end
	if event == "UNIT_DISPLAYPOWER" and unit ~= "player" then return end
	C.Refresh(event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD")
end

function C.Apply(cfg, state)
	C.cfg, C.state = cfg, state
	if C.listener then C.listener:UnregisterAllEvents() end
	if cfg and cfg.enabled == true and C.Option("enabled") == true and C.visuals[C.GetClass()] and state and state.frame then
		if not C.listener then
			C.listener = CreateFrame("Frame")
			C.listener:SetScript("OnEvent", C.OnEvent)
		end
		C.listener:RegisterEvent("PLAYER_TARGET_CHANGED")
		C.listener:RegisterEvent("PLAYER_ENTERING_WORLD")
		C.listener:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
		C.listener:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
		C.listener:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
		if InCombatLockdown() then C.listener:RegisterEvent("PLAYER_REGEN_ENABLED") else C.Layout() end
	end
	C.Refresh(true)
end

function C.AppendSettings(list, context)
	if not C.visuals[C.GetClass()] then return end
	local section = "comboPoints"
	local function get(key)
		local cfg = UF.GetConfig("target").comboPoints
		local value
	if type(cfg) == "table" then value = cfg[key] end
		if value == nil then return C.defaults[key] end
		return value
	end
	local function set(key, value)
		local cfg = UF.GetConfig("target")
		if type(cfg.comboPoints) ~= "table" then cfg.comboPoints = {} end
		cfg.comboPoints[key] = value
		context.refresh()
		if (key == "style" or key == "enabled") and context.refreshSettings then C_Timer.After(0, context.refreshSettings) end
	end
	local function enabled() return get("enabled") == true end
	local function barEnabled() return enabled() and get("style") == "BAR" end
	local function addSlider(key, label, minimum, maximum, step, barOnly)
		local entry = context.slider(label, minimum, maximum, step, function() return get(key) end, function(value) set(key, value) end, C.defaults[key], section, true)
		entry.isEnabled = barOnly and barEnabled or enabled
		if key == "scale" then entry.formatter = function(value) return string.format("%.2f", value) end end
		if key == "frameLevelOffset" then entry.navigationDefaultVerified = true end
		list[#list + 1] = entry
	end
	local function divider(label) list[#list + 1] = { name = label, kind = UF.ui.settingType.Divider, parentId = section } end
	list[#list + 1] = { name = _G.COMBO_POINTS, kind = UF.ui.settingType.Collapsible, id = section, defaultCollapsed = true }
	divider(L["General"])
	list[#list + 1] = context.checkbox(L["UFComboPointsEnable"], enabled, function(value) set("enabled", value == true) end, true, section)
	local style = context.dropdown(L["Display"], { { value = "BLIZZARD", label = L["UFComboPointsBlizzard"] }, { value = "BAR", label = L["UFComboPointsBar"] } }, function() return get("style") end, function(value) set("style", value) end, C.defaults.style, section)
	style.isEnabled = enabled
	list[#list + 1] = style
	divider(L["Layout"])
	local strata = context.dropdown(L["Strata"], UF.ui.strataOptionsWithDefault, function() return get("strata") end, function(value) set("strata", value) end, C.defaults.strata, section)
	strata.isEnabled = enabled
	strata.navigationDefaultVerified = true
	list[#list + 1] = strata
	addSlider("frameLevelOffset", L["UFDetachedPowerLevelOffset"], 0, 50, 1)
	divider(L["Position"])
	local anchor = context.dropdown(L["Anchor"], { { value = "TOP", label = L["Top"] }, { value = "BOTTOM", label = L["Bottom"] } }, function() return get("anchor") end, function(value) set("anchor", value) end, C.defaults.anchor, section)
	anchor.isEnabled = enabled
	list[#list + 1] = anchor
	addSlider("x", L["X Offset"], -3000, 3000, 1)
	addSlider("y", L["Y Offset"], -3000, 3000, 1)
	addSlider("scale", L["Scale"], 0.25, 3, 0.05)
	addSlider("spacing", L["UFComboPointsSpacing"], 0, 20, 1)
	divider(L["Bar"])
	addSlider("width", L["Bar width"], 40, 600, 1, true)
	addSlider("height", L["Bar height"], 2, 40, 1, true)
	local texture = context.dropdown(L["Bar texture"], context.textureOptions, function() return get("texture") end, function(value) set("texture", value) end, C.defaults.texture, section)
	texture.isEnabled = barEnabled
	list[#list + 1] = texture
	for _, spec in ipairs({ { "color", L["Bar color"] }, { "background", L["Background color"] } }) do
		local key = spec[1]
		local function colorGet()
			local color = get(key)
			return { r = color[1], g = color[2], b = color[3], a = color[4] }
		end
		local function colorSet(_, color) set(key, { color.r, color.g, color.b, color.a or 1 }) end
		local default = C.defaults[key]
		list[#list + 1] = { name = spec[2], kind = UF.ui.settingType.Color, parentId = section, hasOpacity = true, default = default, get = function() return get(key) end, set = colorSet, colorGet = colorGet, colorSet = colorSet, colorDefault = { r = default[1], g = default[2], b = default[3], a = default[4] }, isEnabled = barEnabled }
	end
end
