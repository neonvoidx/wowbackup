local _, addon = ...
if not (addon.variables.isForever and not addon.variables.isTBC) then return end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local M = { frames = setmetatable({}, { __mode = "k" }), suffixes = { elite = "+", rareelite = "R+", rare = "R", trivial = "-", minus = "-" } }
addon.NameplateLevel = M
M.defaults = {
	nameplateLevelReplace = false,
	nameplateLevelFont = addon.functions.GetGlobalFontConfigKey(),
	nameplateLevelOutline = addon.functions.GetGlobalFontStyleConfigKey(),
	nameplateLevelSize = 12,
	nameplateLevelAnchor = "RIGHT",
	nameplateLevelOffsetX = 5,
	nameplateLevelOffsetY = 0,
	nameplateLevelDifficulty = true,
	nameplateLevelClassColor = true,
	nameplateLevelClassification = true,
	nameplateLevelColor = { r = 1, g = 1, b = 1, a = 1 },
}
M.anchors = {
	LEFT = { "RIGHT", "LEFT" }, RIGHT = { "LEFT", "RIGHT" },
	TOP = { "BOTTOM", "TOP" }, BOTTOM = { "TOP", "BOTTOM" }, CENTER = { "CENTER", "CENTER" },
	TOPLEFT = { "BOTTOMRIGHT", "TOPLEFT" }, TOPRIGHT = { "BOTTOMLEFT", "TOPRIGHT" },
	BOTTOMLEFT = { "TOPRIGHT", "BOTTOMLEFT" }, BOTTOMRIGHT = { "TOPLEFT", "BOTTOMRIGHT" },
}

function M.InitDB()
	for key, value in pairs(M.defaults) do
		if type(value) == "table" then value = { r = value.r, g = value.g, b = value.b, a = value.a } end
		addon.functions.InitDBValue(key, value)
	end
end

function M.IsEnabled() return addon.db and addon.db.nameplateLevelReplace == true end

function M.Restore(frame, state)
	state.text:Hide()
	if state.alpha ~= nil then
		local original = frame.PlayerLevelDiffFrame
		if original and original:GetAlpha() == 0 then original:SetAlpha(state.alpha) end
		state.alpha = nil
	end
end

function M.Update(frame)
	if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
	local original = frame.PlayerLevelDiffFrame
	local bar = frame.healthBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)
	if not original or not bar then return end
	local state = M.frames[frame]
	if not M.IsEnabled() then
		if state then M.Restore(frame, state) end
		return
	end
	if not state then
		-- Keep the replacement independent of the hidden level indicator's alpha.
		local layer = CreateFrame("Frame", nil, frame)
		layer:SetAllPoints(bar)
		layer:SetFrameLevel(math.max(frame:GetFrameLevel(), original:GetFrameLevel()) + 1)
		state = { text = layer:CreateFontString(nil, "OVERLAY") }
		M.frames[frame] = state
		original:HookScript("OnShow", function()
			if M.IsEnabled() then M.Update(frame) end
		end)
	end
	if state.alpha == nil then state.alpha = original:GetAlpha() end
	original:SetAlpha(0)
	local unit = frame.unit
	if not unit or not UnitExists(unit) or not original:ShouldDisplay(unit) then state.text:Hide(); return end
	local db, text = addon.db, state.text
	local level = UnitEffectiveLevel(unit)
	local classification = UnitClassification(unit)
	local value = level and level > 0 and tostring(level) or "??"
	if classification == "worldboss" then
		value = "??"
	elseif db.nameplateLevelClassification then
		local suffix = M.suffixes[classification]
		if suffix then value = value .. suffix end
	end
	local color = db.nameplateLevelColor or M.defaults.nameplateLevelColor
	if db.nameplateLevelDifficulty and UnitCanAttack("player", unit) then
		color = original:GetDifficultyColor(level > 0 and level - UnitEffectiveLevel("player") or 100)
	end
	if db.nameplateLevelClassColor and UnitIsPlayer(unit) then
		local class = select(2, UnitClass(unit))
		color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or color
	end
	local font = addon.functions.ResolveFontFace(db.nameplateLevelFont, STANDARD_TEXT_FONT)
	local flags = addon.functions.GetFontFlagsForStyle(db.nameplateLevelOutline)
	addon.functions.SetFontWithFallback(text, font, db.nameplateLevelSize or 12, flags or "", STANDARD_TEXT_FONT)
	addon.functions.ApplyFontStyleShadow(text, db.nameplateLevelOutline)
	text:SetText(value)
	text:SetTextColor(color.r, color.g, color.b, color.a or 1)
	local anchor = M.anchors[db.nameplateLevelAnchor] or M.anchors.RIGHT
	text:ClearAllPoints()
	text:SetPoint(anchor[1], bar, anchor[2], db.nameplateLevelOffsetX or 5, db.nameplateLevelOffsetY or 0)
	text:Show()
end

function M.Refresh()
	if not C_NamePlate then return end
	local enabled = M.IsEnabled()
	if M.watcher and M.watching ~= enabled then
		M.watcher:UnregisterAllEvents()
		-- Bootstrap the active profile after login; runtime events are opt-in.
		M.watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
		if enabled then
			for _, event in ipairs(M.events) do M.watcher:RegisterEvent(event) end
		end
		M.watching = enabled
	end
	if not enabled then
		for frame, state in pairs(M.frames) do
			if not (frame.IsForbidden and frame:IsForbidden()) then M.Restore(frame, state) end
		end
		if addon.functions.RefreshDefaultNameplateTargetMarkers then addon.functions.RefreshDefaultNameplateTargetMarkers() end
		return
	end
	if not M.hooked and _G.CompactUnitFrame_UpdatePlayerLevelDiff then
		hooksecurefunc("CompactUnitFrame_UpdatePlayerLevelDiff", function(frame)
			if M.IsEnabled() and frame and frame.unit and frame.unit:match("^nameplate") then M.Update(frame) end
		end)
		M.hooked = true
	end
	for _, plate in ipairs(C_NamePlate.GetNamePlates()) do M.Update(plate.UnitFrame) end
	if addon.functions.RefreshDefaultNameplateTargetMarkers then addon.functions.RefreshDefaultNameplateTargetMarkers() end
end

function M.RegisterSettings(category, section, fontList, fontOrder)
	M.InitDB()
	addon.functions.SettingsCreateHeadline(category, L["Level"], { parentSection = section, groupID = "level", order = 25 })
	local function option(key, label)
		return {
			var = key, text = label, newTagID = key, parentSection = section,
			default = M.defaults[key],
			get = function()
				local value = addon.db[key]
				if value == nil then return M.defaults[key] end
				return value
			end,
			set = function(value) addon.db[key] = value; M.Refresh() end,
			parentCheck = function() return addon.db.nameplateLevelReplace == true end,
		}
	end
	local toggle = option("nameplateLevelReplace", L["nameplateLevelReplace"])
	toggle.desc, toggle.parentCheck = L["nameplateLevelReplaceDesc"], nil
	toggle.func = toggle.set
	addon.functions.SettingsCreateCheckbox(category, toggle)
	for _, entry in ipairs({
		{ "nameplateLevelDifficulty", L["nameplateLevelDifficulty"] },
		{ "nameplateLevelClassColor", L["Level class color"] },
		{ "nameplateLevelClassification", L["nameplateLevelClassification"] },
	}) do
		local data = option(entry[1], entry[2]); data.func = data.set
		addon.functions.SettingsCreateCheckbox(category, data)
	end
	local color = option("nameplateLevelColor", L["Level color"])
	color.parentCheck = function()
		return addon.db.nameplateLevelReplace == true and addon.db.nameplateLevelClassColor ~= true and addon.db.nameplateLevelDifficulty ~= true
	end
	color.callback = M.Refresh
	addon.functions.SettingsCreateColorPicker(category, color)
	local font = option("nameplateLevelFont", L["Level font"])
	font.listFunc, font.order = fontList, fontOrder
	addon.functions.SettingsCreateScrollDropdown(category, font)
	local outline = option("nameplateLevelOutline", L["Level font outline"])
	outline.list, outline.order = addon.functions.GetFontStyleOptions(true)
	addon.functions.SettingsCreateDropdown(category, outline)
	local position = option("nameplateLevelAnchor", L["Position"])
	position.list = {
		TOPLEFT = L["Top Left"], TOP = L["Top"], TOPRIGHT = L["Top Right"],
		LEFT = L["Left"], CENTER = L["Center"], RIGHT = L["Right"],
		BOTTOMLEFT = L["Bottom Left"], BOTTOM = L["Bottom"], BOTTOMRIGHT = L["Bottom Right"],
	}
	position.order = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
	addon.functions.SettingsCreateDropdown(category, position)
	for _, entry in ipairs({
		{ "nameplateLevelSize", "Level font size", 8, 48 },
		{ "nameplateLevelOffsetX", "Level offset X", -100, 100 },
		{ "nameplateLevelOffsetY", "Level offset Y", -100, 100 },
	}) do
		local data = option(entry[1], L[entry[2]])
		data.min, data.max, data.step = entry[3], entry[4], 1
		addon.functions.SettingsCreateSlider(category, data)
	end
	M.Refresh()
end

M.watcher = CreateFrame("Frame")
M.events = { "ADDON_LOADED", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_LEVEL", "UNIT_CLASSIFICATION_CHANGED", "PLAYER_LEVEL_UP" }
M.watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
M.watcher:SetScript("OnEvent", function(_, event, unit)
	if not M.IsEnabled() then
		if event == "PLAYER_ENTERING_WORLD" then M.Refresh() end
		return
	end
	if event == "NAME_PLATE_UNIT_REMOVED" then
		for frame, state in pairs(M.frames) do if frame.unit == unit then state.text:Hide() end end
	elseif event == "UNIT_LEVEL" or event == "UNIT_CLASSIFICATION_CHANGED" then
		if unit == "player" then M.Refresh()
		elseif unit and unit:match("^nameplate") then
			local plate = C_NamePlate.GetNamePlateForUnit(unit)
			if plate then M.Update(plate.UnitFrame) end
		end
	else
		M.Refresh()
	end
end)
