local _, addon = ...
if not (addon.variables.isForever and not addon.variables.isTBC) then return end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local M = { bars = setmetatable({}, { __mode = "k" }) }
addon.ProfessionText = M
M.defaults = {
	professionTextEnabled = false,
	professionTextHideName = false,
	professionTextFont = addon.functions.GetGlobalFontConfigKey(),
	professionTextOutline = addon.functions.GetGlobalFontStyleConfigKey(),
	professionTextSize = 16,
	professionTextAnchor = "CENTER",
	professionTextOffsetX = 0,
	professionTextOffsetY = 0,
	professionTextUseClassColor = true,
	professionTextColor = { r = 1, g = 1, b = 1, a = 1 },
}

function M.IsEnabled() return addon.db and addon.db.professionTextEnabled == true end

function M.Apply(bar)
	local state = M.bars[bar]
	if not state then return end
	local text = bar.Rank.Text
	if state.originalText then
		local value = state.originalText
		if M.IsEnabled() and addon.db.professionTextHideName and state.professionName and state.professionName ~= "" then
			local first, last = value:find(state.professionName, 1, true)
			if first then value = (value:sub(1, first - 1) .. value:sub(last + 1)):match("^%s*(.-)%s*$") end
		end
		text:SetText(value)
	end
	if not M.IsEnabled() then
		if not state.active then return end
		text:SetFont(state.font, state.size, state.flags)
		text:SetTextColor(unpack(state.color))
		text:SetShadowColor(unpack(state.shadowColor))
		text:SetShadowOffset(unpack(state.shadowOffset))
		text:SetSize(state.width, state.height)
		text:ClearAllPoints()
		for _, point in ipairs(state.points) do text:SetPoint(unpack(point)) end
		state.active = nil
		return
	end
	local db = addon.db
	local face = addon.functions.ResolveFontFace(db.professionTextFont, STANDARD_TEXT_FONT)
	local style = db.professionTextOutline or M.defaults.professionTextOutline
	addon.functions.SetFontWithFallback(text, face, db.professionTextSize or 16, addon.functions.GetFontFlagsForStyle(style) or "", STANDARD_TEXT_FONT)
	addon.functions.ApplyFontStyleShadow(text, style)
	local color = db.professionTextColor or M.defaults.professionTextColor
	if db.professionTextUseClassColor then
		local class = select(2, UnitClass("player"))
		color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class] or color
	end
	text:SetTextColor(color.r, color.g, color.b, color.a or 1)
	-- Release the template's fixed nine-pixel height so larger fonts are not clipped.
	text:SetSize(0, 0)
	text:ClearAllPoints()
	text:SetPoint(db.professionTextAnchor or "CENTER", bar.Rank, db.professionTextAnchor or "CENTER", db.professionTextOffsetX or 0, db.professionTextOffsetY or 0)
	state.active = true
end

function M.Track(bar)
	if not bar or M.bars[bar] or not bar.Rank or not bar.Rank.Text or type(bar.Update) ~= "function" then return end
	local text = bar.Rank.Text
	local font, size, flags = text:GetFont()
	local points = {}
	for index = 1, text:GetNumPoints() do points[index] = { text:GetPoint(index) } end
	M.bars[bar] = {
		originalText = text:GetText(),
		font = font, size = size, flags = flags, points = points,
		-- The rank-bar template uses automatic width; GetWidth reports the rendered width.
		color = { text:GetTextColor() }, shadowColor = { text:GetShadowColor() },
		shadowOffset = { text:GetShadowOffset() }, width = 0, height = text:GetHeight(),
	}
	hooksecurefunc(bar, "Update", function(_, professionInfo)
		local state = M.bars[bar]
		state.originalText = text:GetText()
		state.professionName = professionInfo and professionInfo.professionName
		M.Apply(bar)
	end)
	bar:HookScript("OnShow", function() M.Apply(bar) end)
	M.Apply(bar)
end

function M.Discover()
	local mixin = _G.ProfessionsRankBarMixin
	if not mixin then return end
	if not M.hooked then
		-- Future bars copy this hook when the template mixes in OnLoad.
		hooksecurefunc(mixin, "OnLoad", M.Track)
		M.hooked = true
	end
	-- Already-created bars have their own copied methods. Discover them once per
	-- profession addon load, rather than scanning the UI during skill updates.
	local frame = EnumerateFrames()
	while frame do
		if not frame:IsForbidden() and frame.GetMaskWidth == mixin.GetMaskWidth then M.Track(frame) end
		frame = EnumerateFrames(frame)
	end
end

function M.Refresh()
	for bar in pairs(M.bars) do M.Apply(bar) end
end

function M.RegisterSettings(category, fontList, fontOrder)
	addon.functions.CleanupProfessionTextAnchors()
	for key, value in pairs(M.defaults) do
		if type(value) == "table" then value = { r = value.r, g = value.g, b = value.b, a = value.a } end
		addon.functions.InitDBValue(key, value)
	end
	local section = addon.functions.SettingsCreateExpandableSection(category, {
		name = L["Professions"], configPageID = "interface.professions", configPageKey = "Professions",
		newTagID = "professionTextPage", modernCategory = "interface", expanded = false, colorizeTitle = false,
	})
	local function option(key, label)
		return {
			var = key, text = label, newTagID = key, parentSection = section, default = M.defaults[key],
			get = function()
				if addon.db[key] == nil then return M.defaults[key] end
				return addon.db[key]
			end,
			set = function(value) addon.db[key] = value; M.Refresh() end,
			parentCheck = M.IsEnabled,
		}
	end
	local toggle = option("professionTextEnabled", L["professionTextEnabled"])
	toggle.desc, toggle.parentCheck, toggle.func = L["professionTextEnabledDesc"], nil, toggle.set
	addon.functions.SettingsCreateCheckbox(category, toggle)
	local hideName = option("professionTextHideName", L["professionTextHideName"])
	hideName.func = hideName.set
	addon.functions.SettingsCreateCheckbox(category, hideName)
	local font = option("professionTextFont", L["Font"])
	font.listFunc, font.order = fontList, fontOrder
	addon.functions.SettingsCreateScrollDropdown(category, font)
	local outline = option("professionTextOutline", L["Font outline"])
	outline.list, outline.order = addon.functions.GetFontStyleOptions(true)
	addon.functions.SettingsCreateDropdown(category, outline)
	local classColor = option("professionTextUseClassColor", L["Use class color"])
	classColor.func = classColor.set
	addon.functions.SettingsCreateCheckbox(category, classColor)
	local color = option("professionTextColor", L["Text color"])
	color.parentCheck = function() return M.IsEnabled() and addon.db.professionTextUseClassColor ~= true end
	color.callback = M.Refresh
	addon.functions.SettingsCreateColorPicker(category, color)
	local anchor = option("professionTextAnchor", L["Position"])
	anchor.list = {
		LEFT = L["Left"], CENTER = L["Center"], RIGHT = L["Right"],
	}
	anchor.order = { "LEFT", "CENTER", "RIGHT" }
	addon.functions.SettingsCreateDropdown(category, anchor)
	for _, entry in ipairs({
		{ "professionTextSize", "Size", 8, 40 },
		{ "professionTextOffsetX", "Offset X", -200, 200 },
		{ "professionTextOffsetY", "Offset Y", -60, 60 },
	}) do
		local data = option(entry[1], L[entry[2]])
		data.min, data.max, data.step = entry[3], entry[4], 1
		addon.functions.SettingsCreateSlider(category, data)
	end
	M.Discover()
	M.Refresh()
end

M.watcher = CreateFrame("Frame")
M.watcher:RegisterEvent("ADDON_LOADED")
M.watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
M.watcher:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_ENTERING_WORLD" or (name and name:find("^Blizzard_Professions")) then
		M.Discover()
		M.Refresh()
	end
end)
