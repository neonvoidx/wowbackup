local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.UF = addon.Aura.UF or {}
local UF = addon.Aura.UF
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local GF = UF.GroupFrames
local HB = UF.GroupFramesHealerBuffs
local UFHelper = addon.Aura.UFHelper
if not (GF and HB) then return end

UF.GroupFramesHealerBuffEditor = UF.GroupFramesHealerBuffEditor or {}
local Editor = UF.GroupFramesHealerBuffEditor

local max = math.max
local min = math.min
local floor = math.floor
local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local pairs = pairs
local tinsert = table.insert
local sort = table.sort
local wipe = _G.wipe or (table and table.wipe)
local UIDropDownMenu_EnableDropDown = _G.UIDropDownMenu_EnableDropDown
local UIDropDownMenu_DisableDropDown = _G.UIDropDownMenu_DisableDropDown
local UIDropDownMenu_Enable = _G.UIDropDownMenu_Enable
local UIDropDownMenu_Disable = _G.UIDropDownMenu_Disable
local UIDropDownMenu_AddSeparator = _G.UIDropDownMenu_AddSeparator
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local CloseDropDownMenus = _G.CloseDropDownMenus
local ColorPickerFrame = _G.ColorPickerFrame
local OpacitySliderFrame = _G.OpacitySliderFrame
local LOCALIZED_CLASS_NAMES_MALE = _G.LOCALIZED_CLASS_NAMES_MALE or {}
local LOCALIZED_CLASS_NAMES_FEMALE = _G.LOCALIZED_CLASS_NAMES_FEMALE or {}

local GROUP_ROW_HEIGHT = 22
local GROUP_ROW_GAP = 1
local RULE_ROW_HEIGHT = 24
local RULE_ROW_GAP = 2
local GROUP_VISIBLE_ROWS = 9
local RULE_VISIBLE_ROWS = 9
local EMPTY = {}
local BAR_DIMENSION_MAX = 512
local DURATION_COLOR_STEP_MAX = 3

local ASSET_BG_DARK = "Interface\\AddOns\\EnhanceQoL\\Assets\\background_dark.tga"
local ASSET_BG_GRAY = "Interface\\AddOns\\EnhanceQoL\\Assets\\background_gray.tga"
local ASSET_BORDER_PANEL = "Interface\\AddOns\\EnhanceQoL\\Assets\\PanelBorder_"
local ASSET_BORDER_ROUND = "Interface\\AddOns\\EnhanceQoL\\Assets\\border_round_"

local ANCHOR_COORDS = {
	TOPLEFT = { -0.5, 0.5 },
	TOP = { 0, 0.5 },
	TOPRIGHT = { 0.5, 0.5 },
	LEFT = { -0.5, 0 },
	CENTER = { 0, 0 },
	RIGHT = { 0.5, 0 },
	BOTTOMLEFT = { -0.5, -0.5 },
	BOTTOM = { 0, -0.5 },
	BOTTOMRIGHT = { 0.5, -0.5 },
}

local function tr(key, fallback)
	local value = L and L[key]
	if value == nil or value == "" then return fallback or key end
	return value
end

local function formatIndicatorName(id)
	local fmt = tr("UFGroupHealerBuffEditorIndicatorNameFormat", "Indicator %s")
	return string.format(fmt, tostring(id or ""))
end

local function wipeTable(tbl)
	if not tbl then return end
	if wipe then
		wipe(tbl)
	else
		for key in pairs(tbl) do
			tbl[key] = nil
		end
	end
end

local function indexOf(list, value)
	if type(list) ~= "table" then return nil end
	for i = 1, #list do
		if list[i] == value then return i end
	end
	return nil
end

local function styleSupportsRuleColor(style)
	style = tostring(style or ""):upper()
	return style == "SQUARE" or style == "BAR" or style == "BORDER" or style == "TINT"
end

local function roundInt(value)
	local n = tonumber(value) or 0
	if n >= 0 then return floor(n + 0.5) end
	return -floor(math.abs(n) + 0.5)
end

local function getBarControlDimensions(group, frameWidth, frameHeight)
	frameWidth = tonumber(frameWidth) or 0
	frameHeight = tonumber(frameHeight) or 0
	if frameWidth <= 0 then frameWidth = 200 end
	if frameHeight <= 0 then frameHeight = 100 end

	local inset = max(0, roundInt(tonumber(group and group.inset) or 0))
	local availableWidth = max(1, frameWidth - (inset * 2))
	local availableHeight = max(1, frameHeight - (inset * 2))
	local orientation = tostring(group and group.barOrientation or "HORIZONTAL"):upper()
	local thickness = max(1, min(BAR_DIMENSION_MAX, roundInt(tonumber(group and group.barThickness) or 6)))
	local width = tonumber(group and group.barWidth)
	local height = tonumber(group and group.barHeight)

	if width == nil then width = orientation == "VERTICAL" and thickness or availableWidth end
	if height == nil then height = orientation == "VERTICAL" and availableHeight or thickness end

	width = max(1, min(BAR_DIMENSION_MAX, roundInt(width)))
	height = max(1, min(BAR_DIMENSION_MAX, roundInt(height)))
	return width, height
end

local function clampGroupOffsetsForFrame(group, frameWidth, frameHeight)
	if type(group) ~= "table" then return 0, 0 end
	if group.anchorOutside == true then return roundInt(group.x or 0), roundInt(group.y or 0) end
	local style = tostring(group.style or ""):upper()
	if style == "BAR" and HB and HB.GetBarDisplaySize and HB.ClampOffsetsForRegion then
		local barWidth, barHeight, useSizedPlacement = HB.GetBarDisplaySize(group, frameWidth, frameHeight)
		if useSizedPlacement then
			return HB.ClampOffsetsForRegion(group.anchorPoint, group.x, group.y, frameWidth, frameHeight, barWidth, barHeight, max(0, tonumber(group.inset) or 0))
		end
	end
	return HB.ClampOffsets(group.anchorPoint, group.x, group.y, frameWidth, frameHeight, 0)
end

local function applyPanelBorder(frame)
	if not frame then return end
	local borderLayer, borderSubLevel = "BORDER", 0
	local borderPath = ASSET_BORDER_PANEL
	local cornerSize = 70
	local edgeThickness = 70
	local cornerOffsets = 13

	local function makeTex(key, layer, subLevel)
		local tex = frame:CreateTexture(nil, layer or borderLayer, nil, subLevel or borderSubLevel)
		tex:SetTexture(borderPath .. key .. ".tga")
		tex:SetAlpha(0.9)
		return tex
	end

	local tl = makeTex("tl", borderLayer, borderSubLevel + 1)
	tl:SetSize(cornerSize, cornerSize)
	tl:SetPoint("TOPLEFT", frame, "TOPLEFT", -cornerOffsets, cornerOffsets)

	local tr = makeTex("tr", borderLayer, borderSubLevel + 1)
	tr:SetSize(cornerSize, cornerSize)
	tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", cornerOffsets + 8, cornerOffsets)

	local bl = makeTex("bl", borderLayer, borderSubLevel + 1)
	bl:SetSize(cornerSize, cornerSize)
	bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -cornerOffsets, -cornerOffsets)

	local br = makeTex("br", borderLayer, borderSubLevel + 1)
	br:SetSize(cornerSize, cornerSize)
	br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", cornerOffsets + 8, -cornerOffsets)

	local top = makeTex("t", borderLayer, borderSubLevel)
	top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
	top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
	top:SetHeight(edgeThickness)
	top:SetHorizTile(true)

	local bottom = makeTex("b", borderLayer, borderSubLevel)
	bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
	bottom:SetHeight(edgeThickness)
	bottom:SetHorizTile(true)

	local left = makeTex("l", borderLayer, borderSubLevel)
	left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
	left:SetWidth(edgeThickness)
	left:SetVertTile(true)

	local right = makeTex("r", borderLayer, borderSubLevel)
	right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
	right:SetWidth(edgeThickness)
	right:SetVertTile(true)
end

local function applyInsetBorder(frame, offset, alpha)
	if not frame then return end
	offset = offset or 8
	alpha = alpha or 0.72

	local layer, subLevel = "BORDER", 2
	local path = ASSET_BORDER_ROUND
	local cornerSize = 36
	local edgeSize = 36

	frame.eqolInsetParts = frame.eqolInsetParts or {}
	local parts = frame.eqolInsetParts

	local function tex(name)
		if not parts[name] then parts[name] = frame:CreateTexture(nil, layer, nil, subLevel) end
		local t = parts[name]
		t:SetAlpha(alpha)
		t:SetTexture(path .. name .. ".tga")
		t:SetDrawLayer(layer, subLevel)
		return t
	end

	local tl = tex("tl")
	tl:SetSize(cornerSize, cornerSize)
	tl:ClearAllPoints()
	tl:SetPoint("TOPLEFT", frame, "TOPLEFT", offset, -offset)

	local tr = tex("tr")
	tr:SetSize(cornerSize, cornerSize)
	tr:ClearAllPoints()
	tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -offset, -offset)

	local bl = tex("bl")
	bl:SetSize(cornerSize, cornerSize)
	bl:ClearAllPoints()
	bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", offset, offset)

	local br = tex("br")
	br:SetSize(cornerSize, cornerSize)
	br:ClearAllPoints()
	br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -offset, offset)

	local top = tex("t")
	top:ClearAllPoints()
	top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
	top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
	top:SetHeight(edgeSize)
	top:SetHorizTile(true)

	local bottom = tex("b")
	bottom:ClearAllPoints()
	bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
	bottom:SetHeight(edgeSize)
	bottom:SetHorizTile(true)

	local left = tex("l")
	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
	left:SetWidth(edgeSize)
	left:SetVertTile(true)

	local right = tex("r")
	right:ClearAllPoints()
	right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
	right:SetWidth(edgeSize)
	right:SetVertTile(true)
end

local function applyCardBackground(frame, dark)
	if not frame then return end
	frame._eqolCardBg = frame._eqolCardBg or frame:CreateTexture(nil, "BACKGROUND")
	frame._eqolCardBg:SetAllPoints(frame)
	frame._eqolCardBg:SetTexture(dark and ASSET_BG_DARK or ASSET_BG_GRAY)
	frame._eqolCardBg:SetAlpha(dark and 0.92 or 0.86)
	applyInsetBorder(frame, 6, dark and 0.55 or 0.68)
end

local function createLabel(parent, text, size, outline)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText(text or "")
	local font = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	label:SetFont(font, size or 12, outline or "OUTLINE")
	label:SetTextColor(0.96, 0.9, 0.72, 1)
	return label
end

local function createButton(parent, text, width, height)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 120, height or 22)
	button:SetText(text or "")
	return button
end

local function createCheck(parent, text)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	if check.Text and text then
		check.Text:SetText(text)
		check.Text:SetTextColor(1, 1, 1, 1)
	end
	return check
end

local function createEditBox(parent, width)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetAutoFocus(false)
	box:SetSize(width or 180, 24)
	box:SetFontObject(GameFontHighlightSmall)
	return box
end

local function createNumberInput(parent, width, maxLetters)
	local box = createEditBox(parent, width or 72)
	box:SetJustifyH("CENTER")
	box:SetMaxLetters(maxLetters or 8)
	if box.SetNumeric then box:SetNumeric(false) end
	return box
end

local function createSlider(parent, width, minValue, maxValue, step)
	local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
	slider:SetWidth(width or 180)
	slider:SetMinMaxValues(minValue or 0, maxValue or 1)
	slider:SetValueStep(step or 1)
	slider:SetObeyStepOnDrag(true)
	if slider.Low then slider.Low:SetText(tostring(minValue or 0)) end
	if slider.High then slider.High:SetText(tostring(maxValue or 1)) end
	return slider
end

local function createColorSwatchButton(parent, size)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(size or 26, size or 26)
	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = false,
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	button:SetBackdropColor(0, 0, 0, 0.65)
	button:SetBackdropBorderColor(0.28, 0.33, 0.4, 1)
	local swatch = button:CreateTexture(nil, "ARTWORK")
	swatch:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
	swatch:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
	swatch:SetColorTexture(1, 1, 1, 1)
	button.ColorSwatch = swatch
	button._eqolColorSwatch = swatch
	if button.RegisterForClicks then button:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
	return button
end

local function toggleDropdown(dropdown)
	if not dropdown then return end
	if dropdown.Button and dropdown.Button.IsEnabled and not dropdown.Button:IsEnabled() then return end
	if _G.UIDROPDOWNMENU_OPEN_MENU == dropdown then
		if CloseDropDownMenus then CloseDropDownMenus(1) end
		return
	end
	if ToggleDropDownMenu then
		ToggleDropDownMenu(1, nil, dropdown, dropdown, 0, 0)
		return
	end
	local button = dropdown.Button
	if not button and dropdown.GetName and dropdown:GetName() then button = _G[dropdown:GetName() .. "Button"] end
	if not button then return end
	if button.IsEnabled and not button:IsEnabled() then return end
	if button.Click then button:Click() end
end

local function makeDropdownFullyClickable(dropdown)
	if not dropdown or dropdown._eqolFullClick then return end
	dropdown._eqolFullClick = true
	local hit = CreateFrame("Button", nil, dropdown)
	hit:SetAllPoints(dropdown)
	local baseLevel = (dropdown.Button and dropdown.Button.GetFrameLevel and dropdown.Button:GetFrameLevel()) or (dropdown.GetFrameLevel and dropdown:GetFrameLevel()) or 1
	if hit.SetFrameLevel then hit:SetFrameLevel(baseLevel + 1) end
	hit:RegisterForClicks("LeftButtonUp")
	hit:SetScript("OnClick", function() toggleDropdown(dropdown) end)
	hit:EnableMouse(true)
	dropdown._eqolClicker = hit
end

local function createDropdown(parent, width)
	local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetWidth(dropdown, width or 160)
	UIDropDownMenu_SetText(dropdown, "")
	makeDropdownFullyClickable(dropdown)
	return dropdown
end

local function setControlEnabled(control, enabled)
	if not control then return end
	enabled = enabled == true
	if control.SetEnabled then
		control:SetEnabled(enabled)
	elseif enabled then
		if control.Enable then control:Enable() end
		if control.EnableMouse then control:EnableMouse(true) end
	else
		if control.Disable then control:Disable() end
		if control.EnableMouse then control:EnableMouse(false) end
	end

	-- UIDropDownMenuTemplate frames do not expose SetEnabled consistently.
	if control.Button and control.Text then
		if enabled then
			if UIDropDownMenu_EnableDropDown then
				UIDropDownMenu_EnableDropDown(control)
			elseif UIDropDownMenu_Enable then
				UIDropDownMenu_Enable(control)
			end
		else
			if UIDropDownMenu_DisableDropDown then
				UIDropDownMenu_DisableDropDown(control)
			elseif UIDropDownMenu_Disable then
				UIDropDownMenu_Disable(control)
			end
		end
	end
	if control._eqolClicker then
		control._eqolClicker:SetEnabled(enabled)
		control._eqolClicker:EnableMouse(enabled)
	end
end

local function setControlVisible(control, visible)
	if not control then return end
	if visible then
		control:Show()
	else
		control:Hide()
	end
end

local function iconMarkup(icon, size)
	if icon == nil then return "" end
	local s = tostring(size or 14)
	return "|T" .. tostring(icon) .. ":" .. s .. ":" .. s .. ":0:0|t "
end

local function getDropdownOptionText(option, withIcon)
	if not option then return "" end
	local label = option.label or option.text or tostring(option.value)
	if withIcon and option.icon then return iconMarkup(option.icon, 14) .. tostring(label) end
	return tostring(label)
end

local function setDropdown(dropdown, options, selectedValue, onSelect)
	dropdown._eqolOptions = options or {}
	dropdown._eqolSelectedValue = selectedValue
	dropdown._eqolOnSelect = onSelect

	UIDropDownMenu_Initialize(dropdown, function(self, level)
		local opts = dropdown._eqolOptions or {}
		for i = 1, #opts do
			local option = opts[i]
			local info = UIDropDownMenu_CreateInfo()
			info.text = getDropdownOptionText(option, true)
			info.value = option.value
			info.checked = option.value == dropdown._eqolSelectedValue
			info.func = function()
				dropdown._eqolSelectedValue = option.value
				UIDropDownMenu_SetText(dropdown, getDropdownOptionText(option, true))
				if dropdown._eqolOnSelect then dropdown._eqolOnSelect(option.value, option) end
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)

	local selectedText = nil
	for i = 1, #(options or {}) do
		if options[i].value == selectedValue then
			selectedText = getDropdownOptionText(options[i], true)
			break
		end
	end
	if not selectedText then
		if selectedValue ~= nil then
			selectedText = tostring(selectedValue)
		else
			selectedText = tr("UFGroupHealerBuffEditorSelect", "Select")
		end
	end
	UIDropDownMenu_SetText(dropdown, selectedText)
end

local function unpackRgba(color)
	if type(color) == "table" then return tonumber(color[1]) or 1, tonumber(color[2]) or 1, tonumber(color[3]) or 1, tonumber(color[4]) or 1 end
	return 1, 1, 1, 1
end

local function setColorPreview(button, color)
	local r, g, b, a = unpackRgba(color)
	if not button then return end
	local swatch = button.ColorSwatch or button._eqolColorSwatch or button.Swatch
	if swatch and swatch.SetColorTexture then swatch:SetColorTexture(r, g, b, a) end
end

local function showColorPicker(initialColor, onApply)
	if type(onApply) ~= "function" then return end
	local r, g, b, a = unpackRgba(initialColor)
	local useModernPicker = ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow ~= nil
	local isInitializing = false

	local function alphaFromPicker(defaultAlpha)
		if ColorPickerFrame and ColorPickerFrame.GetColorAlpha then
			local alpha = tonumber(ColorPickerFrame:GetColorAlpha())
			if alpha ~= nil then return alpha end
		end
		-- Legacy picker path uses OpacitySliderFrame as inverted alpha.
		if not useModernPicker and OpacitySliderFrame and OpacitySliderFrame.GetValue then
			local opacity = tonumber(OpacitySliderFrame:GetValue())
			if opacity ~= nil then return 1 - opacity end
		end
		return defaultAlpha
	end

	local function applyFromPicker(restore)
		if isInitializing then return end
		local nr, ng, nb, na
		if type(restore) == "table" then
			nr = tonumber(restore.r) or tonumber(restore[1]) or r
			ng = tonumber(restore.g) or tonumber(restore[2]) or g
			nb = tonumber(restore.b) or tonumber(restore[3]) or b
			na = tonumber(restore.a)
			if na == nil and not useModernPicker and restore.opacity ~= nil then na = 1 - (tonumber(restore.opacity) or 0) end
			if na == nil then na = tonumber(restore[4]) or a end
		else
			if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
				nr, ng, nb = ColorPickerFrame:GetColorRGB()
			else
				nr, ng, nb = r, g, b
			end
			na = alphaFromPicker(a)
		end
		nr = min(1, max(0, tonumber(nr) or 1))
		ng = min(1, max(0, tonumber(ng) or 1))
		nb = min(1, max(0, tonumber(nb) or 1))
		na = min(1, max(0, tonumber(na) or 1))
		onApply(nr, ng, nb, na)
	end

	if useModernPicker then
		isInitializing = true
		ColorPickerFrame:SetupColorPickerAndShow({
			r = r,
			g = g,
			b = b,
			opacity = a,
			hasOpacity = true,
			swatchFunc = function() applyFromPicker() end,
			opacityFunc = function() applyFromPicker() end,
			cancelFunc = function(restore) applyFromPicker(restore) end,
		})
		isInitializing = false
		return
	end

	if not ColorPickerFrame then return end
	ColorPickerFrame.hasOpacity = true
	ColorPickerFrame.opacity = 1 - a
	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a, opacity = 1 - a }
	ColorPickerFrame.func = function() applyFromPicker() end
	ColorPickerFrame.opacityFunc = function() applyFromPicker() end
	ColorPickerFrame.cancelFunc = function(restore)
		if type(restore) ~= "table" then restore = ColorPickerFrame.previousValues end
		applyFromPicker(restore)
	end
	ColorPickerFrame:Hide()
	ColorPickerFrame:Show()
end

local function createThinScrollFrameBar(scrollFrame, xOffset)
	if not scrollFrame then return nil end
	local parent = scrollFrame:GetParent() or scrollFrame
	local sb = CreateFrame("Slider", nil, parent)
	sb:SetOrientation("VERTICAL")
	sb:SetWidth(10)
	sb:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", xOffset or 4, 2)
	sb:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", xOffset or 4, -2)
	sb:SetValueStep(1)
	sb:SetObeyStepOnDrag(true)

	sb.track = sb:CreateTexture(nil, "BACKGROUND")
	sb.track:SetPoint("TOP", sb, "TOP", 0, -2)
	sb.track:SetPoint("BOTTOM", sb, "BOTTOM", 0, 2)
	sb.track:SetWidth(1)
	sb.track:SetColorTexture(1, 1, 1, 0.2)

	sb.channel = sb:CreateTexture(nil, "BACKGROUND", nil, -1)
	sb.channel:SetPoint("TOP", sb, "TOP", 0, 0)
	sb.channel:SetPoint("BOTTOM", sb, "BOTTOM", 0, 0)
	sb.channel:SetWidth(6)
	sb.channel:SetColorTexture(0, 0, 0, 0.3)

	local thumb = sb:CreateTexture(nil, "ARTWORK")
	thumb:SetSize(6, 24)
	thumb:SetColorTexture(0.85, 0.9, 1, 0.5)
	sb:SetThumbTexture(thumb)
	sb.thumb = thumb
	sb._suppress = false

	local function applyVisibility(range)
		local hasScroll = range and range > 0
		if sb.thumb then sb.thumb:SetAlpha(hasScroll and 0.5 or 0) end
		if sb.track then sb.track:SetAlpha(hasScroll and 0.22 or 0) end
		if sb.channel then sb.channel:SetAlpha(hasScroll and 0.32 or 0) end
	end

	local function updateRange(_, _, yRange)
		local vrange = yRange
		if vrange == nil and scrollFrame.GetVerticalScrollRange then vrange = scrollFrame:GetVerticalScrollRange() end
		local maxRange = max(0, vrange or 0)
		local clampedScroll = scrollFrame.GetVerticalScroll and (scrollFrame:GetVerticalScroll() or 0) or 0
		if clampedScroll < 0 then clampedScroll = 0 end
		if clampedScroll > maxRange then clampedScroll = maxRange end
		if scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(clampedScroll) end
		sb._suppress = true
		sb:SetMinMaxValues(0, maxRange)
		sb:SetValue(clampedScroll)
		sb._suppress = false
		applyVisibility(maxRange)
	end

	scrollFrame:SetScript("OnScrollRangeChanged", updateRange)
	scrollFrame:SetScript("OnVerticalScroll", function(_, offset)
		sb._suppress = true
		sb:SetValue(offset or 0)
		sb._suppress = false
	end)

	sb:SetScript("OnValueChanged", function(sl, value)
		if sl._suppress then return end
		local minVal, maxVal = sl:GetMinMaxValues()
		value = max(minVal or 0, min(maxVal or 0, roundInt(value or 0)))
		sl._suppress = true
		sl:SetValue(value)
		sl._suppress = false
		scrollFrame:SetVerticalScroll(value)
	end)

	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(_, delta)
		local minVal, maxVal = sb:GetMinMaxValues()
		local cur = sb:GetValue() or 0
		local step = 30
		local nextValue = cur - (delta * step)
		if minVal and nextValue < minVal then nextValue = minVal end
		if maxVal and nextValue > maxVal then nextValue = maxVal end
		sb:SetValue(nextValue)
	end)

	sb:SetScript("OnEnter", function()
		if sb.track then sb.track:SetColorTexture(1, 1, 1, 0.32) end
		if sb.thumb then sb.thumb:SetColorTexture(0.92, 0.95, 1, 0.72) end
	end)
	sb:SetScript("OnLeave", function()
		if sb.track then sb.track:SetColorTexture(1, 1, 1, 0.2) end
		if sb.thumb then sb.thumb:SetColorTexture(0.85, 0.9, 1, 0.5) end
	end)

	function sb:Sync()
		local range = scrollFrame.GetVerticalScrollRange and scrollFrame:GetVerticalScrollRange() or 0
		updateRange(nil, nil, range)
		local clampedScroll = scrollFrame.GetVerticalScroll and (scrollFrame:GetVerticalScroll() or 0) or 0
		if clampedScroll < 0 then clampedScroll = 0 end
		if clampedScroll > range then clampedScroll = range end
		if scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(clampedScroll) end
		sb._suppress = true
		sb:SetValue(clampedScroll)
		sb._suppress = false
	end

	updateRange(nil, nil, scrollFrame.GetVerticalScrollRange and scrollFrame:GetVerticalScrollRange() or 0)
	return sb
end

local function createThinListBar(parent, anchorFrame, xOffset, getMaxValue, getCurrentValue, setCurrentValue)
	if not anchorFrame then return nil end
	local sb = CreateFrame("Slider", nil, parent or anchorFrame:GetParent() or anchorFrame)
	sb:SetOrientation("VERTICAL")
	sb:SetWidth(10)
	sb:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", xOffset or 4, 2)
	sb:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMRIGHT", xOffset or 4, -2)
	sb:SetValueStep(1)
	sb:SetObeyStepOnDrag(true)
	sb:SetMinMaxValues(0, 0)
	sb:SetValue(0)
	sb._suppress = false

	sb.track = sb:CreateTexture(nil, "BACKGROUND")
	sb.track:SetPoint("TOP", sb, "TOP", 0, -2)
	sb.track:SetPoint("BOTTOM", sb, "BOTTOM", 0, 2)
	sb.track:SetWidth(1)
	sb.track:SetColorTexture(1, 1, 1, 0.2)

	sb.channel = sb:CreateTexture(nil, "BACKGROUND", nil, -1)
	sb.channel:SetPoint("TOP", sb, "TOP", 0, 0)
	sb.channel:SetPoint("BOTTOM", sb, "BOTTOM", 0, 0)
	sb.channel:SetWidth(6)
	sb.channel:SetColorTexture(0, 0, 0, 0.3)

	local thumb = sb:CreateTexture(nil, "ARTWORK")
	thumb:SetSize(6, 24)
	thumb:SetColorTexture(0.85, 0.9, 1, 0.5)
	sb:SetThumbTexture(thumb)
	sb.thumb = thumb

	local function applyVisibility(range)
		local hasScroll = range and range > 0
		if sb.thumb then sb.thumb:SetAlpha(hasScroll and 0.5 or 0) end
		if sb.track then sb.track:SetAlpha(hasScroll and 0.22 or 0) end
		if sb.channel then sb.channel:SetAlpha(hasScroll and 0.32 or 0) end
	end

	local function clampToRange(value)
		local minVal, maxVal = sb:GetMinMaxValues()
		value = roundInt(value or 0)
		if minVal and value < minVal then value = minVal end
		if maxVal and value > maxVal then value = maxVal end
		return value
	end

	sb:SetScript("OnValueChanged", function(self, value)
		if self._suppress then return end
		value = clampToRange(value)
		self._suppress = true
		self:SetValue(value)
		self._suppress = false
		if setCurrentValue then setCurrentValue(value) end
	end)

	sb:SetScript("OnEnter", function()
		if sb.track then sb.track:SetColorTexture(1, 1, 1, 0.32) end
		if sb.thumb then sb.thumb:SetColorTexture(0.92, 0.95, 1, 0.72) end
	end)
	sb:SetScript("OnLeave", function()
		if sb.track then sb.track:SetColorTexture(1, 1, 1, 0.2) end
		if sb.thumb then sb.thumb:SetColorTexture(0.85, 0.9, 1, 0.5) end
	end)

	function sb:Sync()
		local maxValue = max(0, roundInt(getMaxValue and getMaxValue() or 0))
		local currentValue = roundInt(getCurrentValue and getCurrentValue() or 0)
		if currentValue < 0 then currentValue = 0 end
		if currentValue > maxValue then currentValue = maxValue end
		self._suppress = true
		self:SetMinMaxValues(0, maxValue)
		self:SetValue(currentValue)
		self._suppress = false
		applyVisibility(maxValue)
	end

	function sb:Step(delta)
		local currentValue = roundInt(getCurrentValue and getCurrentValue() or self:GetValue() or 0)
		self:SetValue(currentValue - roundInt(delta or 0))
	end

	sb:Sync()
	return sb
end

local function getKindConfig(kind)
	local cfg
	if GF and GF.GetHealerBuffPlacementConfig then
		cfg = GF:GetHealerBuffPlacementConfig(kind)
	elseif GF and GF.GetConfig then
		cfg = GF:GetConfig(kind)
	end
	if cfg and HB and HB.EnsureConfig then HB.EnsureConfig(cfg) end
	return cfg
end

local function eachGroupRule(placement, groupId, callback)
	if not (placement and groupId and callback) then return end
	for i = 1, #(placement.ruleOrder or {}) do
		local ruleId = placement.ruleOrder[i]
		local rule = placement.rulesById and placement.rulesById[ruleId]
		if rule and rule.groupId == groupId then callback(ruleId, rule, i) end
	end
end

local function isRuleForClass(rule, classToken)
	if not (rule and classToken) then return false end
	local family = HB.GetFamilyById and HB.GetFamilyById(rule.spellFamilyId)
	return family and family.classToken and tostring(family.classToken) == tostring(classToken)
end

local function groupHasClassRule(placement, groupId, classToken)
	if not (placement and groupId and classToken) then return false end
	for i = 1, #(placement.ruleOrder or EMPTY) do
		local ruleId = placement.ruleOrder[i]
		local rule = placement.rulesById and placement.rulesById[ruleId]
		if rule and rule.groupId == groupId and isRuleForClass(rule, classToken) then return true end
	end
	return false
end

local function buildUsedFamilyMapForGroup(placement, groupId, out)
	out = out or {}
	wipeTable(out)
	if not (placement and groupId) then return out end
	for i = 1, #(placement.ruleOrder or EMPTY) do
		local ruleId = placement.ruleOrder[i]
		local rule = placement.rulesById and placement.rulesById[ruleId]
		local familyId = rule and rule.spellFamilyId
		if rule and rule.groupId == groupId and familyId ~= nil then out[tostring(familyId)] = ruleId end
	end
	return out
end

local function findExistingRuleForGroupFamily(placement, groupId, familyId)
	if not (placement and groupId and familyId ~= nil) then return nil end
	familyId = tostring(familyId)
	for i = 1, #(placement.ruleOrder or EMPTY) do
		local ruleId = placement.ruleOrder[i]
		local rule = placement.rulesById and placement.rulesById[ruleId]
		if rule and rule.groupId == groupId and tostring(rule.spellFamilyId or "") == familyId then return ruleId end
	end
	return nil
end

local function copyArray(src)
	local out = {}
	for i = 1, #(src or EMPTY) do
		out[#out + 1] = src[i]
	end
	return out
end

local function getFamilyPresentation(familyId)
	local family = HB.GetFamilyById and HB.GetFamilyById(familyId)
	if not family then return tostring(familyId or ""), nil, nil, nil end
	local name = family._resolvedName or family.fallbackName or family.id or tostring(familyId or "")
	local icon = family._resolvedIcon
	return tostring(name), icon, family.classToken, family.spec
end

local function getFamilyLabel(familyId, withIcon)
	local name, icon = getFamilyPresentation(familyId)
	if withIcon and icon then return iconMarkup(icon, 14) .. name end
	return name
end

local function buildFamilyOptionsForEditor(classTokenFilter)
	local raw = HB.GetFamilyOptions and HB.GetFamilyOptions() or {}
	local list = {}
	for i = 1, #raw do
		local option = raw[i]
		local name, icon, classToken, spec = getFamilyPresentation(option.value)
		if classTokenFilter == nil or (classToken and tostring(classToken) == tostring(classTokenFilter)) then
			list[#list + 1] = {
				value = option.value,
				label = name,
				icon = option.icon or icon,
				classToken = classToken or option.classToken,
				spec = spec or option.spec,
			}
		end
	end
	sort(list, function(a, b)
		local al = tostring(a.label or "")
		local bl = tostring(b.label or "")
		if al == bl then return tostring(a.value) < tostring(b.value) end
		return al < bl
	end)
	return list
end

local function getClassDisplayName(classToken)
	if classToken == nil then return tr("Other", "Other") end
	local token = tostring(classToken)
	return tostring(LOCALIZED_CLASS_NAMES_MALE[token] or LOCALIZED_CLASS_NAMES_FEMALE[token] or token)
end

local function buildFamilyOptionsByClass(classTokenFilter)
	local options = buildFamilyOptionsForEditor(classTokenFilter)
	local buckets, classOrder = {}, {}
	for i = 1, #options do
		local option = options[i]
		local classToken = option.classToken and tostring(option.classToken) or "_OTHER"
		local bucket = buckets[classToken]
		if bucket == nil then
			bucket = {
				token = classToken,
				label = getClassDisplayName(option.classToken),
				spells = {},
			}
			buckets[classToken] = bucket
			classOrder[#classOrder + 1] = classToken
		end
		bucket.spells[#bucket.spells + 1] = option
	end
	sort(classOrder, function(a, b)
		local left = buckets[a]
		local right = buckets[b]
		if left == nil or right == nil then return tostring(a) < tostring(b) end
		if left.label == right.label then return tostring(left.token) < tostring(right.token) end
		return tostring(left.label) < tostring(right.label)
	end)
	for i = 1, #classOrder do
		local bucket = buckets[classOrder[i]]
		if bucket and bucket.spells then
			sort(bucket.spells, function(a, b)
				local al = tostring(a and a.label or "")
				local bl = tostring(b and b.label or "")
				if al == bl then return tostring(a and a.value or "") < tostring(b and b.value or "") end
				return al < bl
			end)
		end
	end
	return buckets, classOrder
end

local function buildStyleOptionsForMenu()
	local raw = HB.STYLE_OPTIONS or EMPTY
	local list = {}
	for i = 1, #raw do
		list[#list + 1] = raw[i]
	end
	sort(list, function(a, b)
		local left = tostring((a and (a.label or a.text or a.value)) or "")
		local right = tostring((b and (b.label or b.text or b.value)) or "")
		if left == right then return tostring(a and a.value or "") < tostring(b and b.value or "") end
		return left < right
	end)
	return list
end

local function buildBorderOptionsForMenu()
	local list = {}
	local seen = {}
	local function add(value, label)
		local key = tostring(value or ""):lower()
		if key == "" or seen[key] then return end
		seen[key] = true
		list[#list + 1] = { value = value, label = label }
	end
	add("DEFAULT", tr("UFGroupHealerBuffEditorIndicatorBorderTextureDefault", "Default (Border)"))
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames("border") or EMPTY
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash("border") or EMPTY
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
	end
	sort(list, function(a, b)
		local av = tostring(a and a.value or "")
		local bv = tostring(b and b.value or "")
		if av == "DEFAULT" then return true end
		if bv == "DEFAULT" then return false end
		local al = tostring(a and a.label or av)
		local bl = tostring(b and b.label or bv)
		if al == bl then return av < bv end
		return al < bl
	end)
	return list
end

local function buildFrameStrataOptionsForMenu()
	local raw = (GF and GF._FRAME_STRATA_OPTIONS_WITH_DEFAULT)
		or {
			{ value = "", label = DEFAULT or "Default" },
			{ value = "BACKGROUND", label = "BACKGROUND" },
			{ value = "LOW", label = "LOW" },
			{ value = "MEDIUM", label = "MEDIUM" },
			{ value = "HIGH", label = "HIGH" },
			{ value = "DIALOG", label = "DIALOG" },
			{ value = "FULLSCREEN", label = "FULLSCREEN" },
			{ value = "FULLSCREEN_DIALOG", label = "FULLSCREEN_DIALOG" },
			{ value = "TOOLTIP", label = "TOOLTIP" },
		}
	local list = {}
	for i = 1, #raw do
		local option = raw[i]
		list[#list + 1] = { value = option.value or "", label = option.label or tostring(option.value or "") }
	end
	return list
end

local function normalizeFrameStrataToken(value)
	if GF and GF.NormalizeFrameStrataToken then return GF.NormalizeFrameStrataToken(value) end
	if type(value) ~= "string" or value == "" then return nil end
	local token = value:upper()
	if token == "DEFAULT" then return nil end
	if
		token == "BACKGROUND"
		or token == "LOW"
		or token == "MEDIUM"
		or token == "HIGH"
		or token == "DIALOG"
		or token == "FULLSCREEN"
		or token == "FULLSCREEN_DIALOG"
		or token == "TOOLTIP"
	then
		return token
	end
	return nil
end

local function getGroupLabel(placement, groupId)
	if not placement or not groupId then return tostring(groupId or "") end
	local group = placement.groupsById and placement.groupsById[groupId]
	if not group then return tostring(groupId) end
	return tostring(group.name or formatIndicatorName(groupId))
end

local function getVisibleGroupIds(placement, out, classToken)
	out = out or {}
	wipeTable(out)
	if not placement then return out end
	for i = 1, #(placement.groupOrder or EMPTY) do
		local groupId = placement.groupOrder[i]
		local group = groupId and placement.groupsById and placement.groupsById[groupId]
		if group then
			if classToken == nil or groupHasClassRule(placement, groupId, classToken) then out[#out + 1] = groupId end
		end
	end
	return out
end

local function getVisibleRuleIds(placement, groupId, out, classToken)
	out = out or {}
	wipeTable(out)
	if not placement then return out end
	for i = 1, #(placement.ruleOrder or EMPTY) do
		local ruleId = placement.ruleOrder[i]
		local rule = placement.rulesById and placement.rulesById[ruleId]
		if rule and (groupId == nil or rule.groupId == groupId) then
			if classToken == nil or isRuleForClass(rule, classToken) then out[#out + 1] = ruleId end
		end
	end
	return out
end

local function getFirstRuleIdForGroup(placement, groupId)
	if not (placement and groupId) then return nil end
	for i = 1, #(placement.ruleOrder or EMPTY) do
		local ruleId = placement.ruleOrder[i]
		local rule = placement.rulesById and placement.rulesById[ruleId]
		if rule and rule.groupId == groupId then return ruleId end
	end
	return nil
end

local function moveIdInOrder(order, fromId, targetId)
	if type(order) ~= "table" then return false end
	if fromId == nil or targetId == nil or fromId == targetId then return false end
	local fromIndex, toIndex
	for i = 1, #order do
		local id = order[i]
		if id == fromId then fromIndex = i end
		if id == targetId then toIndex = i end
	end
	if not fromIndex or not toIndex then return false end
	table.remove(order, fromIndex)
	table.insert(order, toIndex, fromId)
	return true
end

local function setDangerButtonStyle(button)
	if not button then return end
	if button.GetFontString and button:GetFontString() then
		local fs = button:GetFontString()
		fs:SetTextColor(1, 0.3, 0.3, 1)
		fs:SetShadowOffset(1, -1)
	end
	button:SetNormalFontObject(GameFontHighlightSmall)
	button:SetHighlightFontObject(GameFontHighlightSmall)
	button:SetDisabledFontObject(GameFontDisableSmall)
end

function Editor:QueueRuntimeRefresh()
	if self._refreshQueued then return end
	self._refreshQueued = true
	if C_Timer and C_Timer.After then
		C_Timer.After(0.03, function()
			Editor._refreshQueued = nil
			if not (Editor.frame and Editor.frame:IsShown()) then return end
			if GF and GF.RefreshHealerBuffPlacement then GF:RefreshHealerBuffPlacement() end
		end)
	else
		self._refreshQueued = nil
		if GF and GF.RefreshHealerBuffPlacement then GF:RefreshHealerBuffPlacement() end
	end
end

function Editor:RefreshRuntimeNow()
	if GF and GF.RefreshHealerBuffPlacement then GF:RefreshHealerBuffPlacement() end
end

function Editor:GetContext()
	if not self.kind then return nil, nil end
	local cfg = getKindConfig(self.kind)
	if not cfg then return nil, nil end
	local placement = cfg.healerBuffPlacement
	if not placement then return nil, nil end
	return cfg, placement
end

function Editor:EnsureSelection()
	local _, placement = self:GetContext()
	if not placement then
		self.selectedGroupId = nil
		self.selectedRuleId = nil
		return
	end
	if self.selectedGroupId == nil or not (placement.groupsById and placement.groupsById[self.selectedGroupId]) then self.selectedGroupId = placement.groupOrder and placement.groupOrder[1] or nil end
	local selectedRule = self.selectedRuleId and placement.rulesById and placement.rulesById[self.selectedRuleId]
	if selectedRule and self.selectedGroupId and selectedRule.groupId ~= self.selectedGroupId then selectedRule = nil end
	if selectedRule == nil then
		self.selectedRuleId = getFirstRuleIdForGroup(placement, self.selectedGroupId)
		if self.selectedRuleId == nil then self.selectedRuleId = placement.ruleOrder and placement.ruleOrder[1] or nil end
	end
end

function Editor:SyncSelectedRuleToGroup(force)
	local _, placement = self:GetContext()
	if not placement then
		self.selectedRuleId = nil
		return
	end
	if not self.selectedGroupId or not (placement.groupsById and placement.groupsById[self.selectedGroupId]) then
		if force and placement.ruleOrder then self.selectedRuleId = placement.ruleOrder[1] end
		return
	end
	local selectedRule = self.selectedRuleId and placement.rulesById and placement.rulesById[self.selectedRuleId]
	if force or not selectedRule or selectedRule.groupId ~= self.selectedGroupId then
		self.selectedRuleId = getFirstRuleIdForGroup(placement, self.selectedGroupId)
		if force then self.ruleOffset = 0 end
	end
end

function Editor:EnsureFrame()
	if self.frame then return self.frame end

	local frame = CreateFrame("Frame", "EQOL_UF_GroupHealerBuffEditor", UIParent, "BackdropTemplate")
	frame:SetSize(1120, 760)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(600)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	local frameShade = frame:CreateTexture(nil, "BACKGROUND")
	frameShade:SetAllPoints(frame)
	frameShade:SetTexture(ASSET_BG_DARK)
	frameShade:SetAlpha(0.94)
	frame.FrameShade = frameShade
	applyPanelBorder(frame)
	frame:Hide()

	local title = createLabel(frame, tr("UFGroupHealerBuffEditorTitle", "Healer Buff Placement"), 15, "OUTLINE")
	title:SetPoint("TOPLEFT", 18, -14)
	frame.Title = title

	local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	subtitle:SetText(tr("UFGroupHealerBuffEditorSubtitle", "Configure shared spell-family placements for Party and Raid frames."))
	subtitle:SetTextColor(0.75, 0.75, 0.75, 1)
	frame.Subtitle = subtitle

	local closeButton = CreateFrame("Button", nil, frame, "BackdropTemplate")
	closeButton:SetSize(22, 22)
	closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 20, 12)
	closeButton:SetFrameStrata(frame:GetFrameStrata())
	closeButton:SetFrameLevel((frame:GetFrameLevel() or 1) + 20)
	closeButton:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = false,
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	closeButton:SetBackdropColor(0.35, 0.08, 0.08, 0.95)
	closeButton:SetBackdropBorderColor(0.82, 0.24, 0.24, 1)
	closeButton.Text = closeButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	closeButton.Text:SetPoint("CENTER", 0, 0)
	closeButton.Text:SetText("X")
	closeButton.Text:SetTextColor(1, 0.9, 0.9, 1)
	closeButton:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0.46, 0.1, 0.1, 0.98)
		self:SetBackdropBorderColor(1, 0.35, 0.35, 1)
	end)
	closeButton:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0.35, 0.08, 0.08, 0.95)
		self:SetBackdropBorderColor(0.82, 0.24, 0.24, 1)
	end)
	closeButton:SetScript("OnClick", function() frame:Hide() end)
	frame.CloseButton = closeButton

	local kindLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	kindLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -14)
	kindLabel:SetText(tr("UFGroupHealerBuffEditorScopeLabel", "Scope:"))
	frame.KindLabel = kindLabel

	local kindValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	kindValue:SetPoint("LEFT", kindLabel, "RIGHT", 8, 0)
	kindValue:SetText(tr("UFGroupHealerBuffEditorScopeShared", "Shared (Party + Raid)"))
	frame.KindValue = kindValue

	local enabledCheck = createCheck(frame, tr("UFGroupHealerBuffEditorEnabled", "Enable Healer Buff Placement"))
	enabledCheck:SetPoint("LEFT", kindValue, "RIGHT", 20, 0)
	frame.EnabledCheck = enabledCheck

	local groupPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	groupPanel:SetSize(330, 286)
	groupPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -106)
	applyCardBackground(groupPanel, false)
	frame.GroupPanel = groupPanel

	local groupTitle = createLabel(groupPanel, tr("UFGroupHealerBuffEditorIndicators", "Indicators"), 12, "OUTLINE")
	groupTitle:SetPoint("TOPLEFT", 10, -10)
	groupPanel.Title = groupTitle

	local addGroup = createButton(groupPanel, "+", 22, 20)
	addGroup:SetPoint("TOPRIGHT", -10, -8)
	setDangerButtonStyle(addGroup)
	groupPanel.AddButton = addGroup

	local groupUp = createButton(groupPanel, tr("Up", "Up"), 45, 20)
	groupUp:SetPoint("TOPRIGHT", addGroup, "TOPLEFT", -6, 0)
	groupPanel.UpButton = groupUp

	local groupDown = createButton(groupPanel, tr("Down", "Down"), 45, 20)
	groupDown:SetPoint("TOPRIGHT", groupUp, "TOPLEFT", -6, 0)
	groupPanel.DownButton = groupDown

	local deleteGroup = createButton(groupPanel, tr("UFGroupHealerBuffEditorDelete", "Delete"), 65, 20)
	deleteGroup:SetPoint("TOPRIGHT", groupDown, "TOPLEFT", -6, 0)
	groupPanel.DeleteButton = deleteGroup
	groupUp:Hide()
	groupDown:Hide()
	deleteGroup:Hide()

	groupPanel.RowHolder = CreateFrame("Frame", nil, groupPanel)
	groupPanel.RowHolder:SetPoint("TOPLEFT", groupTitle, "BOTTOMLEFT", 0, -10)
	groupPanel.RowHolder:SetPoint("BOTTOMRIGHT", groupPanel, "BOTTOMRIGHT", -26, 10)

	groupPanel.Rows = {}
	for i = 1, GROUP_VISIBLE_ROWS do
		local row = CreateFrame("Button", nil, groupPanel.RowHolder, "BackdropTemplate")
		row:SetHeight(GROUP_ROW_HEIGHT)
		row:SetPoint("TOPLEFT", groupPanel.RowHolder, "TOPLEFT", 0, -((i - 1) * (GROUP_ROW_HEIGHT + GROUP_ROW_GAP)))
		row:SetPoint("TOPRIGHT", groupPanel.RowHolder, "TOPRIGHT", 0, -((i - 1) * (GROUP_ROW_HEIGHT + GROUP_ROW_GAP)))
		row:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tile = false,
			edgeSize = 1,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		row:SetBackdropColor(0.07, 0.09, 0.12, 0.82)
		row:SetBackdropBorderColor(0.2, 0.26, 0.32, 0.9)
		row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.Text:SetPoint("LEFT", 6, 0)
		row.Text:SetPoint("RIGHT", -28, 0)
		row.Text:SetJustifyH("LEFT")
		row.Text:SetText("")
		row:RegisterForDrag("LeftButton")
		row:EnableMouseWheel(true)
		row.DeleteButton = createButton(row, "x", 18, 18)
		row.DeleteButton:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		setDangerButtonStyle(row.DeleteButton)
		row:SetScript("OnMouseWheel", function(_, delta)
			if groupPanel.ScrollBar then groupPanel.ScrollBar:Step(delta) end
		end)
		row:Hide()
		groupPanel.Rows[i] = row
	end
	groupPanel.ScrollBar = createThinListBar(groupPanel, groupPanel.RowHolder, 2, function()
		local _, placement = Editor:GetContext()
		local count = placement and placement.groupOrder and #placement.groupOrder or 0
		return max(0, count - GROUP_VISIBLE_ROWS)
	end, function() return Editor.groupOffset or 0 end, function(value)
		Editor.groupOffset = roundInt(value or 0)
		Editor:RefreshGroupList()
	end)
	groupPanel.RowHolder:EnableMouseWheel(true)
	groupPanel.RowHolder:SetScript("OnMouseWheel", function(_, delta)
		if groupPanel.ScrollBar then groupPanel.ScrollBar:Step(delta) end
	end)

	local rulePanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	rulePanel:SetSize(420, 286)
	rulePanel:SetPoint("TOPLEFT", groupPanel, "TOPRIGHT", 10, 0)
	applyCardBackground(rulePanel, false)
	frame.RulePanel = rulePanel

	local ruleTitle = createLabel(rulePanel, tr("UFGroupHealerBuffEditorSpellRules", "Spell Rules"), 12, "OUTLINE")
	ruleTitle:SetPoint("TOPLEFT", 10, -10)
	rulePanel.Title = ruleTitle

	local addRule = createButton(rulePanel, tr("UFGroupHealerBuffEditorCreate", "Create"), 70, 20)
	addRule:SetPoint("TOPRIGHT", -10, -8)
	addRule:SetSize(22, 20)
	addRule:SetText("+")
	setDangerButtonStyle(addRule)
	rulePanel.AddButton = addRule

	local ruleUp = createButton(rulePanel, tr("Up", "Up"), 45, 20)
	ruleUp:SetPoint("TOPRIGHT", addRule, "TOPLEFT", -6, 0)
	rulePanel.UpButton = ruleUp

	local ruleDown = createButton(rulePanel, tr("Down", "Down"), 45, 20)
	ruleDown:SetPoint("TOPRIGHT", ruleUp, "TOPLEFT", -6, 0)
	rulePanel.DownButton = ruleDown

	local deleteRule = createButton(rulePanel, tr("UFGroupHealerBuffEditorDelete", "Delete"), 65, 20)
	deleteRule:SetPoint("TOPRIGHT", ruleDown, "TOPLEFT", -6, 0)
	rulePanel.DeleteButton = deleteRule
	ruleUp:Hide()
	ruleDown:Hide()
	deleteRule:Hide()

	rulePanel.RowHolder = CreateFrame("Frame", nil, rulePanel)
	rulePanel.RowHolder:SetPoint("TOPLEFT", ruleTitle, "BOTTOMLEFT", 0, -8)
	rulePanel.RowHolder:SetPoint("BOTTOMRIGHT", rulePanel, "BOTTOMRIGHT", -18, 10)

	rulePanel.Rows = {}
	for i = 1, RULE_VISIBLE_ROWS do
		local row = CreateFrame("Button", nil, rulePanel.RowHolder, "BackdropTemplate")
		row:SetHeight(RULE_ROW_HEIGHT)
		row:SetPoint("TOPLEFT", rulePanel.RowHolder, "TOPLEFT", 0, -((i - 1) * (RULE_ROW_HEIGHT + RULE_ROW_GAP)))
		row:SetPoint("TOPRIGHT", rulePanel.RowHolder, "TOPRIGHT", 0, -((i - 1) * (RULE_ROW_HEIGHT + RULE_ROW_GAP)))
		row:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tile = false,
			edgeSize = 1,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		row:SetBackdropColor(0.07, 0.09, 0.12, 0.82)
		row:SetBackdropBorderColor(0.2, 0.26, 0.32, 0.9)
		row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.Text:SetPoint("LEFT", 6, 0)
		row.Text:SetPoint("RIGHT", -28, 0)
		row.Text:SetJustifyH("LEFT")
		row.Text:SetText("")
		row:RegisterForDrag("LeftButton")
		row:EnableMouseWheel(true)
		row.DeleteButton = createButton(row, "x", 18, 18)
		row.DeleteButton:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		setDangerButtonStyle(row.DeleteButton)
		row:SetScript("OnMouseWheel", function(_, delta)
			if rulePanel.ScrollBar then rulePanel.ScrollBar:Step(delta) end
		end)
		row:Hide()
		rulePanel.Rows[i] = row
	end
	rulePanel.ScrollBar = createThinListBar(rulePanel, rulePanel.RowHolder, 4, function()
		local _, placement = Editor:GetContext()
		if not placement then return 0 end
		if Editor.selectedGroupId == nil then return 0 end
		local visible = getVisibleRuleIds(placement, Editor.selectedGroupId, Editor._ruleScrollScratch)
		Editor._ruleScrollScratch = visible
		return max(0, #visible - RULE_VISIBLE_ROWS)
	end, function() return Editor.ruleOffset or 0 end, function(value)
		Editor.ruleOffset = roundInt(value or 0)
		Editor:RefreshRuleList()
	end)
	rulePanel.RowHolder:EnableMouseWheel(true)
	rulePanel.RowHolder:SetScript("OnMouseWheel", function(_, delta)
		if rulePanel.ScrollBar then rulePanel.ScrollBar:Step(delta) end
	end)

	local previewPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	previewPanel:SetSize(334, 286)
	previewPanel:SetPoint("TOPLEFT", rulePanel, "TOPRIGHT", 10, 0)
	applyCardBackground(previewPanel, false)
	frame.PreviewPanel = previewPanel

	local previewTitle = createLabel(previewPanel, tr("UFGroupHealerBuffEditorLivePreview", "Live Preview"), 12, "OUTLINE")
	previewTitle:SetPoint("TOPLEFT", 10, -10)
	previewPanel.Title = previewTitle

	local previewLoop = createCheck(previewPanel, tr("UFGroupHealerBuffEditorLoopLivePreview", "Loop Live Preview"))
	previewLoop:SetPoint("LEFT", previewTitle, "RIGHT", 14, -4)
	previewLoop:SetChecked(Editor._previewLoopEnabled == true)
	previewPanel.LoopCheck = previewLoop

	local previewAll = createCheck(previewPanel, tr("UFGroupHealerBuffEditorPreviewAll", "Preview All"))
	previewAll:SetPoint("LEFT", previewLoop.Text, "RIGHT", 6, 0)
	previewAll:SetChecked(Editor._previewAllEnabled ~= false)
	previewPanel.AllCheck = previewAll

	local previewFrame = CreateFrame("Frame", nil, previewPanel, "BackdropTemplate")
	previewFrame:SetPoint("TOPLEFT", previewTitle, "BOTTOMLEFT", 0, -8)
	previewFrame:SetPoint("TOPRIGHT", previewPanel, "TOPRIGHT", -10, -30)
	previewFrame:SetHeight(238)
	applyCardBackground(previewFrame, true)
	previewFrame:SetClipsChildren(true)
	previewPanel.Frame = previewFrame

	local unitFrame = CreateFrame("Frame", nil, previewFrame, "BackdropTemplate")
	unitFrame:SetSize(250, 118)
	unitFrame:SetPoint("CENTER")
	unitFrame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = false,
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	unitFrame:SetBackdropColor(0.07, 0.08, 0.095, 0.98)
	unitFrame:SetBackdropBorderColor(0.38, 0.44, 0.5, 0.95)
	previewFrame.UnitFrame = unitFrame

	local health = unitFrame:CreateTexture(nil, "BACKGROUND")
	health:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 0, 0)
	health:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", 0, 14)
	health:SetDrawLayer("ARTWORK", 1)
	health:SetColorTexture(0.08, 0.42, 0.19, 1)
	unitFrame.HealthTexture = health

	local power = unitFrame:CreateTexture(nil, "BACKGROUND")
	power:SetPoint("BOTTOMLEFT", unitFrame, "BOTTOMLEFT", 0, 0)
	power:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", 0, 0)
	power:SetHeight(14)
	power:SetDrawLayer("ARTWORK", 2)
	power:SetColorTexture(0.1, 0.18, 0.45, 1)
	unitFrame.PowerTexture = power

	local nameText = unitFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	nameText:SetPoint("CENTER", unitFrame, "CENTER", 0, 4)
	nameText:SetText(tr("UFGroupHealerBuffEditorPreviewUnit", "Preview Unit"))
	unitFrame.NameText = nameText

	unitFrame.SampleIcons = {}
	for i = 1, 40 do
		local icon = CreateFrame("Frame", nil, unitFrame, "BackdropTemplate")
		icon:SetSize(14, 14)
		icon:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tile = false,
			edgeSize = 1,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		icon:SetBackdropColor(0, 0, 0, 0.3)
		icon:SetBackdropBorderColor(0, 0, 0, 0.8)
		icon.Texture = icon:CreateTexture(nil, "ARTWORK")
		icon.Texture:SetAllPoints(icon)
		icon.Texture:SetTexture(134400)
		icon:Hide()
		unitFrame.SampleIcons[i] = icon
	end

	unitFrame.SampleTints = {}
	for i = 1, 24 do
		local tint = unitFrame:CreateTexture(nil, "ARTWORK", nil, 2)
		tint:SetAllPoints(unitFrame)
		tint:SetColorTexture(0, 0, 0, 0)
		tint:Hide()
		unitFrame.SampleTints[i] = tint
	end

	unitFrame.SampleBars = {}
	for i = 1, 24 do
		local bar = CreateFrame("StatusBar", nil, unitFrame)
		bar:EnableMouse(false)
		bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
		bar:Hide()
		unitFrame.SampleBars[i] = bar
	end

	unitFrame.SampleBorders = {}
	for i = 1, 24 do
		local border = CreateFrame("Frame", nil, unitFrame, "BackdropTemplate")
		border:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tile = false,
			edgeSize = 2,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		border:SetBackdropColor(0, 0, 0, 0)
		border:Hide()
		unitFrame.SampleBorders[i] = border
	end

	local settingsPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	settingsPanel:SetPoint("TOPLEFT", groupPanel, "BOTTOMLEFT", 0, -10)
	settingsPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
	applyCardBackground(settingsPanel, false)
	frame.SettingsPanel = settingsPanel

	local groupSettingsTitle = createLabel(settingsPanel, tr("UFGroupHealerBuffEditorIndicatorSettings", "Indicator Settings"), 12, "OUTLINE")
	groupSettingsTitle:SetPoint("TOPLEFT", 14, -10)
	settingsPanel.GroupSettingsTitle = groupSettingsTitle

	local groupControlCard = CreateFrame("Frame", nil, settingsPanel, "BackdropTemplate")
	groupControlCard:SetPoint("TOPLEFT", groupSettingsTitle, "BOTTOMLEFT", -4, -6)
	groupControlCard:SetPoint("BOTTOMLEFT", settingsPanel, "BOTTOMLEFT", 10, 10)
	groupControlCard:SetWidth(540)
	applyCardBackground(groupControlCard, true)

	local groupControlViewport = CreateFrame("ScrollFrame", nil, groupControlCard)
	groupControlViewport:SetPoint("TOPLEFT", groupControlCard, "TOPLEFT", 12, -10)
	groupControlViewport:SetPoint("BOTTOMRIGHT", groupControlCard, "BOTTOMRIGHT", -20, 10)
	settingsPanel.GroupControlViewport = groupControlViewport

	local groupControlContent = CreateFrame("Frame", nil, groupControlViewport)
	groupControlContent:SetPoint("TOPLEFT", groupControlViewport, "TOPLEFT", 0, 0)
	groupControlContent:SetHeight(860)
	groupControlContent:SetWidth(500)
	groupControlViewport:SetScrollChild(groupControlContent)
	settingsPanel.GroupControlContent = groupControlContent

	local groupControlScroll = createThinScrollFrameBar(groupControlViewport, 4)
	settingsPanel.GroupControlScroll = groupControlScroll

	local function updateGroupControlScroll()
		local viewportWidth = max(1, (groupControlViewport:GetWidth() or 1) - 6)
		groupControlContent:SetWidth(viewportWidth)
		if groupControlScroll and groupControlScroll.Sync then groupControlScroll:Sync() end
	end
	frame._updateGroupControlScroll = updateGroupControlScroll

	local ruleSettingsTitle = createLabel(settingsPanel, tr("UFGroupHealerBuffEditorRuleSettings", "Rule Settings"), 12, "OUTLINE")
	ruleSettingsTitle:SetPoint("TOPLEFT", 572, -10)
	settingsPanel.RuleSettingsTitle = ruleSettingsTitle

	local ruleControlCard = CreateFrame("Frame", nil, settingsPanel, "BackdropTemplate")
	ruleControlCard:SetPoint("TOPLEFT", ruleSettingsTitle, "BOTTOMLEFT", -4, -6)
	ruleControlCard:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT", -10, 10)
	applyCardBackground(ruleControlCard, true)

	local ruleControlViewport = CreateFrame("ScrollFrame", nil, ruleControlCard)
	ruleControlViewport:SetPoint("TOPLEFT", ruleControlCard, "TOPLEFT", 12, -10)
	ruleControlViewport:SetPoint("BOTTOMRIGHT", ruleControlCard, "BOTTOMRIGHT", -20, 10)
	settingsPanel.RuleControlViewport = ruleControlViewport

	local ruleControlContent = CreateFrame("Frame", nil, ruleControlViewport)
	ruleControlContent:SetPoint("TOPLEFT", ruleControlViewport, "TOPLEFT", 0, 0)
	ruleControlContent:SetHeight(260)
	ruleControlContent:SetWidth(480)
	ruleControlViewport:SetScrollChild(ruleControlContent)
	settingsPanel.RuleControlContent = ruleControlContent

	local ruleControlScroll = createThinScrollFrameBar(ruleControlViewport, 4)
	settingsPanel.RuleControlScroll = ruleControlScroll

	local function updateRuleControlScroll()
		local viewportWidth = max(1, (ruleControlViewport:GetWidth() or 1) - 6)
		ruleControlContent:SetWidth(viewportWidth)
		if ruleControlScroll and ruleControlScroll.Sync then ruleControlScroll:Sync() end
	end
	frame._updateRuleControlScroll = updateRuleControlScroll

	local controls = {}
	frame.Controls = controls
	local groupControlParent = groupControlContent
	local ruleControlParent = ruleControlContent
	controls.PreviewLoop = previewPanel.LoopCheck
	controls.PreviewAll = previewPanel.AllCheck

	controls.GroupNameLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.GroupNameLabel:SetPoint("TOPLEFT", groupControlParent, "TOPLEFT", 0, 0)
	controls.GroupNameLabel:SetText(tr("Name", "Name"))
	controls.GroupName = createEditBox(groupControlParent, 220)
	controls.GroupName:SetPoint("TOPLEFT", controls.GroupNameLabel, "TOPRIGHT", 12, 0)

	controls.GroupStyleLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.GroupStyleLabel:SetPoint("TOPLEFT", controls.GroupNameLabel, "BOTTOMLEFT", 0, -16)
	controls.GroupStyleLabel:SetText(tr("UFGroupHealerBuffEditorStyleLocked", "Style (locked)"))
	controls.GroupStyleValue = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	controls.GroupStyleValue:SetPoint("LEFT", controls.GroupStyleLabel, "TOPRIGHT", 10, -2)
	controls.GroupStyleValue:SetWidth(190)
	controls.GroupStyleValue:SetJustifyH("LEFT")
	controls.GroupStyleValue:SetText("-")

	controls.GroupAnchorLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.GroupAnchorLabel:SetPoint("TOPLEFT", controls.GroupStyleLabel, "BOTTOMLEFT", 0, -18)
	controls.GroupAnchorLabel:SetText(tr("Anchor", "Anchor"))
	controls.GroupAnchor = createDropdown(groupControlParent, 160)
	controls.GroupAnchor:SetPoint("TOPLEFT", controls.GroupAnchorLabel, "TOPRIGHT", 0, 12)
	controls.GroupAnchorOutside = createCheck(groupControlParent, tr("Anchor outside frame", "Anchor outside frame"))
	controls.GroupAnchorOutside:SetPoint("TOPLEFT", controls.GroupAnchorLabel, "BOTTOMLEFT", -4, -8)

	controls.GroupGrowthLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.GroupGrowthLabel:SetPoint("TOPLEFT", controls.GroupAnchorLabel, "BOTTOMLEFT", 0, -18)
	controls.GroupGrowthLabel:SetText(tr("Growth", "Growth"))
	controls.GroupGrowth = createDropdown(groupControlParent, 160)
	controls.GroupGrowth:SetPoint("TOPLEFT", controls.GroupGrowthLabel, "TOPRIGHT", 0, 12)

	controls.GroupBarOrientationLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.GroupBarOrientationLabel:SetPoint("TOPLEFT", controls.GroupGrowthLabel, "BOTTOMLEFT", 0, -18)
	controls.GroupBarOrientationLabel:SetText(tr("UFGroupHealerBuffEditorBarOrientation", "Bar Orientation"))
	controls.GroupBarOrientation = createDropdown(groupControlParent, 160)
	controls.GroupBarOrientation:SetPoint("TOPLEFT", controls.GroupBarOrientationLabel, "TOPRIGHT", 0, 12)

	local function createSettingSlider(anchorLabel, text, minValue, maxValue, step)
		local label = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", 0, -22)
		label:SetText(text)
		local slider = createSlider(groupControlParent, 180, minValue, maxValue, step)
		slider:SetPoint("TOPLEFT", label, "TOPRIGHT", 8, 8)
		local valueInput = createNumberInput(groupControlParent, 56, 8)
		valueInput:SetPoint("LEFT", slider, "RIGHT", 14, 0)
		valueInput:SetText("0")
		return label, slider, valueInput
	end

	controls.PerRowLabel, controls.PerRow, controls.PerRowValue = createSettingSlider(controls.GroupBarOrientationLabel, tr("UFGroupHealerBuffEditorPerRow", "Per Row"), 1, 20, 1)
	controls.MaxLabel, controls.MaxCount, controls.MaxValue = createSettingSlider(controls.PerRowLabel, tr("Max", "Max"), 0, 40, 1)
	controls.SpacingLabel, controls.Spacing, controls.SpacingValue = createSettingSlider(controls.MaxLabel, tr("Spacing", "Spacing"), 0, 20, 1)
	controls.SizeLabel, controls.Size, controls.SizeValue = createSettingSlider(controls.SpacingLabel, tr("UFGroupHealerBuffEditorIconSize", "Icon Size"), 4, 64, 1)
	controls.IconZoomLabel, controls.IconZoom, controls.IconZoomValue = createSettingSlider(controls.SizeLabel, tr("Icon zoom", "Icon zoom"), 0, 35, 1)
	controls.CooldownTextSizeLabel, controls.CooldownTextSize, controls.CooldownTextSizeValue =
		createSettingSlider(controls.IconZoomLabel, tr("UFGroupHealerBuffEditorCooldownTextSize", "Cooldown Size"), 6, 64, 1)
	controls.ChargeTextSizeLabel, controls.ChargeTextSize, controls.ChargeTextSizeValue =
		createSettingSlider(controls.CooldownTextSizeLabel, tr("UFGroupHealerBuffEditorChargeTextSize", "Charge Size"), 6, 64, 1)
	controls.XLabel, controls.XOffset, controls.XValue = createSettingSlider(controls.ChargeTextSizeLabel, tr("X Offset", "X Offset"), -200, 200, 1)
	controls.YLabel, controls.YOffset, controls.YValue = createSettingSlider(controls.XLabel, tr("Y Offset", "Y Offset"), -200, 200, 1)
	controls.BarWidthLabel, controls.BarWidth, controls.BarWidthValue = createSettingSlider(controls.YLabel, tr("Bar width", "Bar width"), 1, BAR_DIMENSION_MAX, 1)
	controls.BarHeightLabel, controls.BarHeight, controls.BarHeightValue = createSettingSlider(controls.BarWidthLabel, tr("Bar height", "Bar height"), 1, BAR_DIMENSION_MAX, 1)
	controls.BarAlphaLabel, controls.BarAlpha, controls.BarAlphaValue = createSettingSlider(controls.BarHeightLabel, tr("Alpha", "Alpha"), 0, 1, 0.01)
	controls.BarStrataLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.BarStrataLabel:SetPoint("TOPLEFT", controls.BarAlphaLabel, "BOTTOMLEFT", 0, -18)
	controls.BarStrataLabel:SetText(tr("UFGroupHealerBuffEditorBarStrata", "Strata"))
	controls.BarStrata = createDropdown(groupControlParent, 180)
	controls.BarStrata:SetPoint("TOPLEFT", controls.BarStrataLabel, "TOPRIGHT", 0, 12)
	controls.BarFrameLevelLabel, controls.BarFrameLevel, controls.BarFrameLevelValue =
		createSettingSlider(controls.BarStrataLabel, tr("UFGroupHealerBuffEditorBarLevel", "Level"), -20, 1000, 1)
	controls.InsetLabel, controls.Inset, controls.InsetValue = createSettingSlider(controls.BarFrameLevelLabel, tr("UFGroupHealerBuffEditorInset", "Inset"), 0, 40, 1)
	controls.BorderSizeLabel, controls.BorderSize, controls.BorderSizeValue = createSettingSlider(controls.InsetLabel, tr("Border Size", "Border Size"), 1, 16, 1)
	controls.BorderStrataLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.BorderStrataLabel:SetPoint("TOPLEFT", controls.BorderSizeLabel, "BOTTOMLEFT", 0, -18)
	controls.BorderStrataLabel:SetText(tr("UFGroupHealerBuffEditorBorderStrata", "Strata"))
	controls.BorderStrata = createDropdown(groupControlParent, 180)
	controls.BorderStrata:SetPoint("TOPLEFT", controls.BorderStrataLabel, "TOPRIGHT", 0, 12)
	controls.BorderFrameLevelLabel, controls.BorderFrameLevel, controls.BorderFrameLevelValue =
		createSettingSlider(controls.BorderStrataLabel, tr("UFGroupHealerBuffEditorBorderLevel", "Level"), -20, 1000, 1)
	controls.IndicatorBorder = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorIndicatorBorderEnabled", "Indicator Border"))
	controls.IndicatorBorder:SetPoint("TOPLEFT", controls.BorderFrameLevelLabel, "BOTTOMLEFT", -4, -8)
	controls.IndicatorBorderTextureLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.IndicatorBorderTextureLabel:SetPoint("TOPLEFT", controls.IndicatorBorder, "BOTTOMLEFT", 4, -18)
	controls.IndicatorBorderTextureLabel:SetText(tr("UFGroupHealerBuffEditorIndicatorBorderTexture", "Border Texture"))
	controls.IndicatorBorderTexture = createDropdown(groupControlParent, 180)
	controls.IndicatorBorderTexture:SetPoint("TOPLEFT", controls.IndicatorBorderTextureLabel, "TOPRIGHT", 0, 12)
	controls.IndicatorBorderSizeLabel, controls.IndicatorBorderSize, controls.IndicatorBorderSizeValue =
		createSettingSlider(controls.IndicatorBorderTextureLabel, tr("Border Size", "Border Size"), 1, 24, 1)
	controls.IndicatorBorderOffsetLabel, controls.IndicatorBorderOffset, controls.IndicatorBorderOffsetValue =
		createSettingSlider(controls.IndicatorBorderSizeLabel, tr("UFGroupHealerBuffEditorIndicatorBorderOffset", "Border Offset"), -12, 12, 1)
	controls.IndicatorBorderColorLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.IndicatorBorderColorLabel:SetPoint("TOPLEFT", controls.IndicatorBorderOffsetLabel, "BOTTOMLEFT", 0, -22)
	controls.IndicatorBorderColorLabel:SetText(tr("UFGroupHealerBuffEditorIndicatorBorderColor", "Border Color"))
	controls.IndicatorBorderColorButton = createColorSwatchButton(groupControlParent, 26)
	controls.IndicatorBorderColorButton:SetPoint("LEFT", controls.IndicatorBorderColorLabel, "RIGHT", 10, 0)

	controls.ColorLabel = groupControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.ColorLabel:SetPoint("TOPLEFT", controls.IndicatorBorderColorLabel, "BOTTOMLEFT", 0, -22)
	controls.ColorLabel:SetText(COLOR)
	controls.ColorButton = createColorSwatchButton(groupControlParent, 26)
	controls.ColorButton:SetPoint("LEFT", controls.ColorLabel, "RIGHT", 10, 0)
	controls.ColorSwatch = controls.ColorButton.ColorSwatch
	controls.ColorButton.ColorSwatch = controls.ColorSwatch
	controls.ColorButton._eqolColorSwatch = controls.ColorSwatch
	controls.BarFillFrame = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorBarFillFrame", "Fill Full Frame"))
	controls.BarFillFrame:SetPoint("TOPLEFT", controls.ColorLabel, "BOTTOMLEFT", -4, -8)
	controls.BarDrainAnimation = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorBarDrainAnimation", "Drain Animation (First Match)"))
	controls.BarDrainAnimation:SetPoint("TOPLEFT", controls.BarFillFrame, "BOTTOMLEFT", 0, -4)
	controls.BarReverseFill = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorBarReverseFill", "Reverse"))
	controls.BarReverseFill:SetPoint("TOPLEFT", controls.BarDrainAnimation, "BOTTOMLEFT", 0, -4)
	controls.CooldownSwipe = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorCooldownSwipe", "Cooldown Swipe"))
	controls.CooldownSwipe:SetPoint("TOPLEFT", controls.BarReverseFill, "BOTTOMLEFT", 0, -4)
	controls.CooldownEdge = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorCooldownEdge", "Draw Edge"))
	controls.CooldownEdge:SetPoint("TOPLEFT", controls.CooldownSwipe, "BOTTOMLEFT", 0, -4)
	controls.CooldownBling = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorCooldownBling", "Draw Bling"))
	controls.CooldownBling:SetPoint("TOPLEFT", controls.CooldownEdge, "BOTTOMLEFT", 0, -4)
	controls.HideCooldownText = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorHideCooldownText", "Hide Cooldown Text"))
	controls.HideCooldownText:SetPoint("TOPLEFT", controls.CooldownBling, "BOTTOMLEFT", 0, -4)
	controls.HideChargeText = createCheck(groupControlParent, tr("UFGroupHealerBuffEditorHideChargeText", "Hide Charge Text"))
	controls.HideChargeText:SetPoint("TOPLEFT", controls.HideCooldownText, "BOTTOMLEFT", 0, -4)
	groupControlContent:SetHeight(340)

	local function layoutGroupControlRows()
		local LABEL_X = 8
		local CONTROL_X = 84
		local SLIDER_X = CONTROL_X + 28
		local FIRST_ROW_Y = -8
		local GAP_DROPDOWN = 20
		local GAP_SLIDER = 20
		local GAP_COLOR = 20
		local GAP_CHECK = 16
		local prevLabel
		local lastBottom

		local function includeBottom(control)
			if control and control:IsShown() then lastBottom = control end
		end

		local function beginRow(label, gap)
			label:ClearAllPoints()
			if prevLabel then
				label:SetPoint("TOPLEFT", prevLabel, "BOTTOMLEFT", 0, -(gap or GAP_DROPDOWN))
			else
				label:SetPoint("TOPLEFT", groupControlParent, "TOPLEFT", LABEL_X, FIRST_ROW_Y)
			end
			prevLabel = label
		end

		controls.GroupNameLabel:ClearAllPoints()
		controls.GroupNameLabel:SetPoint("TOPLEFT", groupControlParent, "TOPLEFT", LABEL_X, FIRST_ROW_Y)
		controls.GroupName:ClearAllPoints()
		controls.GroupName:SetPoint("TOPLEFT", controls.GroupNameLabel, "TOPLEFT", CONTROL_X - LABEL_X, 2)
		prevLabel = controls.GroupNameLabel
		includeBottom(controls.GroupName)

		local function placeDropdown(label, control)
			if not (label:IsShown() and control:IsShown()) then return end
			beginRow(label, GAP_DROPDOWN)
			control:ClearAllPoints()
			control:SetPoint("TOPLEFT", label, "TOPLEFT", CONTROL_X - LABEL_X, 12)
			includeBottom(control)
		end

		local function placeSlider(label, slider, valueText)
			if not (label:IsShown() and slider:IsShown() and valueText:IsShown()) then return end
			beginRow(label, GAP_SLIDER)
			slider:ClearAllPoints()
			slider:SetPoint("TOPLEFT", label, "TOPLEFT", SLIDER_X - LABEL_X, 8)
			valueText:ClearAllPoints()
			valueText:SetPoint("LEFT", slider, "RIGHT", 14, 0)
			includeBottom(slider)
			includeBottom(valueText)
		end

		local function placeColor(label, button)
			if not (label:IsShown() and button:IsShown()) then return end
			beginRow(label, GAP_COLOR)
			button:ClearAllPoints()
			button:SetPoint("LEFT", label, "RIGHT", 10, 0)
			includeBottom(button)
		end

		local function placeCheck(check, anchorControl, xOffset, yOffset)
			if not (check and check:IsShown()) then return end
			check:ClearAllPoints()
			if anchorControl and anchorControl:IsShown() then
				check:SetPoint("TOPLEFT", anchorControl, "BOTTOMLEFT", xOffset or 0, yOffset or -4)
			elseif prevLabel then
				check:SetPoint("TOPLEFT", prevLabel, "BOTTOMLEFT", 0, -GAP_CHECK)
			else
				check:SetPoint("TOPLEFT", groupControlParent, "TOPLEFT", LABEL_X, FIRST_ROW_Y)
			end
			prevLabel = check
			includeBottom(check)
		end

		placeDropdown(controls.GroupAnchorLabel, controls.GroupAnchor)
		placeCheck(controls.GroupAnchorOutside)
		placeDropdown(controls.GroupGrowthLabel, controls.GroupGrowth)
		placeDropdown(controls.GroupBarOrientationLabel, controls.GroupBarOrientation)

		placeSlider(controls.PerRowLabel, controls.PerRow, controls.PerRowValue)
		placeSlider(controls.MaxLabel, controls.MaxCount, controls.MaxValue)
		placeSlider(controls.SpacingLabel, controls.Spacing, controls.SpacingValue)
		placeSlider(controls.SizeLabel, controls.Size, controls.SizeValue)
		placeSlider(controls.IconZoomLabel, controls.IconZoom, controls.IconZoomValue)
		placeSlider(controls.CooldownTextSizeLabel, controls.CooldownTextSize, controls.CooldownTextSizeValue)
		placeSlider(controls.ChargeTextSizeLabel, controls.ChargeTextSize, controls.ChargeTextSizeValue)
		placeSlider(controls.XLabel, controls.XOffset, controls.XValue)
		placeSlider(controls.YLabel, controls.YOffset, controls.YValue)
		placeSlider(controls.BarWidthLabel, controls.BarWidth, controls.BarWidthValue)
		placeSlider(controls.BarHeightLabel, controls.BarHeight, controls.BarHeightValue)
		placeSlider(controls.BarAlphaLabel, controls.BarAlpha, controls.BarAlphaValue)
		placeDropdown(controls.BarStrataLabel, controls.BarStrata)
		placeSlider(controls.BarFrameLevelLabel, controls.BarFrameLevel, controls.BarFrameLevelValue)
		placeSlider(controls.InsetLabel, controls.Inset, controls.InsetValue)
		placeSlider(controls.BorderSizeLabel, controls.BorderSize, controls.BorderSizeValue)
		placeDropdown(controls.BorderStrataLabel, controls.BorderStrata)
		placeSlider(controls.BorderFrameLevelLabel, controls.BorderFrameLevel, controls.BorderFrameLevelValue)
		placeCheck(controls.IndicatorBorder, nil, -4, -8)
		placeDropdown(controls.IndicatorBorderTextureLabel, controls.IndicatorBorderTexture)
		placeSlider(controls.IndicatorBorderSizeLabel, controls.IndicatorBorderSize, controls.IndicatorBorderSizeValue)
		placeSlider(controls.IndicatorBorderOffsetLabel, controls.IndicatorBorderOffset, controls.IndicatorBorderOffsetValue)
		placeColor(controls.IndicatorBorderColorLabel, controls.IndicatorBorderColorButton)
		placeColor(controls.ColorLabel, controls.ColorButton)
		placeCheck(controls.BarFillFrame, controls.ColorLabel, -4, -8)
		placeCheck(controls.BarDrainAnimation, controls.BarFillFrame, 0, -4)
		placeCheck(controls.BarReverseFill, controls.BarDrainAnimation, 0, -4)
		local cooldownAnchor = controls.BarReverseFill
		if not (cooldownAnchor and cooldownAnchor:IsShown()) then
			cooldownAnchor = controls.BarDrainAnimation
			if not (cooldownAnchor and cooldownAnchor:IsShown()) then
				cooldownAnchor = controls.BarFillFrame
				if not (cooldownAnchor and cooldownAnchor:IsShown()) then cooldownAnchor = controls.ColorLabel end
				if not (cooldownAnchor and cooldownAnchor:IsShown()) and controls.IndicatorBorderColorLabel and controls.IndicatorBorderColorLabel:IsShown() then
					cooldownAnchor = controls.IndicatorBorderColorLabel
				elseif controls.IndicatorBorderColorButton and controls.IndicatorBorderColorButton:IsShown() then
					cooldownAnchor = controls.IndicatorBorderColorButton
				elseif controls.IndicatorBorderOffsetLabel and controls.IndicatorBorderOffsetLabel:IsShown() then
					cooldownAnchor = controls.IndicatorBorderOffsetLabel
				elseif controls.IndicatorBorderOffset and controls.IndicatorBorderOffset:IsShown() then
					cooldownAnchor = controls.IndicatorBorderOffset
				elseif controls.IndicatorBorderSizeLabel and controls.IndicatorBorderSizeLabel:IsShown() then
					cooldownAnchor = controls.IndicatorBorderSizeLabel
				elseif controls.IndicatorBorderTextureLabel and controls.IndicatorBorderTextureLabel:IsShown() then
					cooldownAnchor = controls.IndicatorBorderTextureLabel
				elseif controls.IndicatorBorder and controls.IndicatorBorder:IsShown() then
					cooldownAnchor = controls.IndicatorBorder
				elseif controls.YLabel and controls.YLabel:IsShown() then
					cooldownAnchor = controls.YLabel
				elseif controls.XLabel and controls.XLabel:IsShown() then
					cooldownAnchor = controls.XLabel
				elseif controls.YOffset and controls.YOffset:IsShown() then
					cooldownAnchor = controls.YOffset
				elseif controls.XOffset and controls.XOffset:IsShown() then
					cooldownAnchor = controls.XOffset
				end
			end
		end
		placeCheck(controls.CooldownSwipe, cooldownAnchor, -4, -8)
		placeCheck(controls.CooldownEdge, controls.CooldownSwipe, 0, -4)
		placeCheck(controls.CooldownBling, controls.CooldownEdge, 0, -4)
		placeCheck(controls.HideCooldownText, controls.CooldownBling, 0, -4)
		placeCheck(controls.HideChargeText, controls.HideCooldownText, 0, -4)

		local top = controls.GroupNameLabel:GetTop()
		local bottom = lastBottom and lastBottom:GetBottom()
		local height = 260
		if top and bottom then height = (top - bottom) + 34 end
		if height < 220 then height = 220 end
		groupControlContent:SetHeight(height)
	end
	frame._layoutGroupControlRows = layoutGroupControlRows

	controls.RuleEnabled = createCheck(ruleControlParent, tr("UFGroupHealerBuffEditorRuleEnabled", "Rule enabled"))
	controls.RuleEnabled:SetPoint("TOPLEFT", ruleControlParent, "TOPLEFT", 0, -2)

	controls.RuleNot = createCheck(ruleControlParent, tr("UFGroupHealerBuffEditorRuleNot", "NOT (active when missing)"))
	controls.RuleNot:SetPoint("TOPLEFT", controls.RuleEnabled, "BOTTOMLEFT", 0, -6)

	controls.RuleMissingDesaturate = createCheck(ruleControlParent, tr("UFGroupHealerBuffEditorRuleMissingDesaturate", "Desaturate missing icon"))
	controls.RuleMissingDesaturate:SetPoint("TOPLEFT", controls.RuleNot, "BOTTOMLEFT", 16, -6)
	controls.RuleMissingDesaturate:Hide()

	controls.RuleExpirationPulse = createCheck(ruleControlParent, tr("UFGroupHealerBuffEditorRuleExpirationPulse", "Pulse when expiring"))
	controls.RuleExpirationPulse:SetPoint("TOPLEFT", controls.RuleNot, "BOTTOMLEFT", 0, -6)
	controls.RuleExpirationPulse:Hide()
	controls.RuleExpirationPulseThresholdLabel = ruleControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.RuleExpirationPulseThresholdLabel:SetPoint("TOPLEFT", controls.RuleExpirationPulse, "BOTTOMLEFT", 4, -18)
	controls.RuleExpirationPulseThresholdLabel:SetText(tr("UFGroupHealerBuffEditorRuleExpirationPulseThreshold", "Pulse window"))
	controls.RuleExpirationPulseThreshold = createSlider(ruleControlParent, 130, 1, 10, 1)
	controls.RuleExpirationPulseThreshold:SetPoint("TOPLEFT", controls.RuleExpirationPulseThresholdLabel, "TOPRIGHT", 10, 8)
	controls.RuleExpirationPulseThresholdValue = createNumberInput(ruleControlParent, 48, 8)
	controls.RuleExpirationPulseThresholdValue:SetPoint("LEFT", controls.RuleExpirationPulseThreshold, "RIGHT", 12, 0)
	controls.RuleExpirationPulseThresholdValue:SetText("3")
	controls.RuleExpirationPulseThresholdLabel:Hide()
	controls.RuleExpirationPulseThreshold:Hide()
	controls.RuleExpirationPulseThresholdValue:Hide()
	controls.RuleExpirationPulseColorLabel = ruleControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.RuleExpirationPulseColorLabel:SetPoint("TOPLEFT", controls.RuleExpirationPulseThresholdLabel, "BOTTOMLEFT", -4, -14)
	controls.RuleExpirationPulseColorLabel:SetText(tr("UFGroupHealerBuffEditorRuleExpirationPulseColor", "Pulse color"))
	controls.RuleExpirationPulseColorButton = createColorSwatchButton(ruleControlParent, 24)
	controls.RuleExpirationPulseColorButton:SetPoint("LEFT", controls.RuleExpirationPulseColorLabel, "RIGHT", 10, 0)
	controls.RuleExpirationPulseColorLabel:Hide()
	controls.RuleExpirationPulseColorButton:Hide()
	controls.RuleExpirationPulseCountdownOnly = createCheck(ruleControlParent, tr("UFGroupHealerBuffEditorRuleExpirationPulseCountdownOnly", "Countdown only during pulse"))
	controls.RuleExpirationPulseCountdownOnly:SetPoint("TOPLEFT", controls.RuleExpirationPulseColorLabel, "BOTTOMLEFT", -4, -10)
	controls.RuleExpirationPulseCountdownOnly:Hide()

	controls.RuleAppliesParty = createCheck(ruleControlParent, tr("Party", "Party"))
	controls.RuleAppliesParty:SetPoint("TOPLEFT", controls.RuleMissingDesaturate, "BOTTOMLEFT", -16, -6)

	controls.RuleAppliesRaid = createCheck(ruleControlParent, tr("Raid", "Raid"))
	controls.RuleAppliesRaid:SetPoint("TOPLEFT", controls.RuleAppliesParty, "BOTTOMLEFT", 0, -6)

	controls.RuleIconModeLabel = ruleControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.RuleIconModeLabel:SetPoint("TOPLEFT", controls.RuleAppliesRaid, "BOTTOMLEFT", 0, -14)
	controls.RuleIconModeLabel:SetText(tr("UFGroupHealerBuffEditorIconRuleMode", "Icon Rule Mode"))
	controls.RuleIconMode = createDropdown(ruleControlParent, 260)
	controls.RuleIconMode:SetPoint("TOPLEFT", controls.RuleIconModeLabel, "TOPRIGHT", 0, 12)
	controls.RuleIconModeLabel:Hide()
	controls.RuleIconMode:Hide()

	controls.RuleMatchLabel = ruleControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.RuleMatchLabel:SetPoint("TOPLEFT", controls.RuleAppliesRaid, "BOTTOMLEFT", 0, -14)
	controls.RuleMatchLabel:SetText(tr("UFGroupHealerBuffEditorTintTrigger", "Tint Trigger"))
	controls.RuleMatch = createDropdown(ruleControlParent, 260)
	controls.RuleMatch:SetPoint("TOPLEFT", controls.RuleMatchLabel, "TOPRIGHT", 0, 12)
	controls.RuleMatchLabel:Hide()
	controls.RuleMatch:Hide()

	controls.RuleColorLabel = ruleControlParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	controls.RuleColorLabel:SetPoint("TOPLEFT", controls.RuleAppliesRaid, "BOTTOMLEFT", 0, -14)
	controls.RuleColorLabel:SetText(tr("UFGroupHealerBuffEditorSpellColor", "Spell Color"))
	controls.RuleColorButton = createColorSwatchButton(ruleControlParent, 24)
	controls.RuleColorButton:SetPoint("LEFT", controls.RuleColorLabel, "RIGHT", 10, 0)
	controls.RuleColorLabel:Hide()
	controls.RuleColorButton:Hide()

	controls.DurationColorSteps = {}
	local durationStepAnchor = controls.RuleColorLabel
	for i = 1, DURATION_COLOR_STEP_MAX do
		local stepControls = {}
		stepControls.Enabled = createCheck(ruleControlParent, string.format(tr("UFGroupHealerBuffEditorDurationColorStep", "Duration Color %d"), i))
		stepControls.Enabled:SetPoint("TOPLEFT", durationStepAnchor, "BOTTOMLEFT", 0, -8)
		stepControls.Seconds = createNumberInput(ruleControlParent, 48, 4)
		stepControls.Seconds:SetPoint("LEFT", stepControls.Enabled.Text or stepControls.Enabled, "RIGHT", 12, 0)
		stepControls.SecondsLabel = ruleControlParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		stepControls.SecondsLabel:SetPoint("LEFT", stepControls.Seconds, "RIGHT", 6, 0)
		stepControls.SecondsLabel:SetText(tr("UFGroupHealerBuffEditorDurationColorSeconds", "sec left"))
		stepControls.ColorButton = createColorSwatchButton(ruleControlParent, 24)
		stepControls.ColorButton:SetPoint("LEFT", stepControls.SecondsLabel, "RIGHT", 10, 0)
		stepControls.Enabled:Hide()
		stepControls.Seconds:Hide()
		stepControls.SecondsLabel:Hide()
		stepControls.ColorButton:Hide()
		controls.DurationColorSteps[i] = stepControls
		durationStepAnchor = stepControls.Enabled
	end

	controls.RuleInfo = ruleControlParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	controls.RuleInfo:SetPoint("TOPLEFT", controls.RuleAppliesRaid, "BOTTOMLEFT", 0, -10)
	controls.RuleInfo:SetPoint("RIGHT", ruleControlParent, "RIGHT", -4, 0)
	controls.RuleInfo:SetJustifyH("LEFT")
	controls.RuleInfo:SetTextColor(0.75, 0.75, 0.75, 1)
	controls.RuleInfo:SetText(tr("UFGroupHealerBuffEditorRuleInfoDefaultHint", "Add rules via + and remove them via x in the list."))

	self.frame = frame
	self.groupOffset = 0
	self.ruleOffset = 0
	self._controlUpdateLock = nil

	local function createGroupFromStyle(style)
		local _, placement = Editor:GetContext()
		if not placement then return end
		style = tostring(style or "ICON")
		local newId = HB.GetNextGroupId and HB.GetNextGroupId(placement) or tostring((#placement.groupOrder or 0) + 1)
		local group = HB.CreateDefaultGroup and HB.CreateDefaultGroup(newId) or { id = newId, name = formatIndicatorName(newId), style = style }
		group.style = style
		if group.name == nil or group.name == "" or tostring(group.name):match("^Group%s+") then group.name = formatIndicatorName(newId) end
		if style == "TINT" then
			group.color = group.color or { 1, 0.82, 0.1, 0.22 }
			if (group.color[4] or 1) > 0.35 then group.color[4] = 0.22 end
		end
		placement.groupsById[newId] = group
		tinsert(placement.groupOrder, newId)
		Editor.selectedGroupId = newId
		Editor:SyncSelectedRuleToGroup(true)
		Editor:RefreshAll()
		Editor:RefreshRuntimeNow()
	end

	local function deleteGroupById(groupId)
		local _, placement = Editor:GetContext()
		if not (placement and groupId) then return end
		placement.groupsById[groupId] = nil
		for i = #placement.groupOrder, 1, -1 do
			if placement.groupOrder[i] == groupId then table.remove(placement.groupOrder, i) end
		end
		for i = #placement.ruleOrder, 1, -1 do
			local ruleId = placement.ruleOrder[i]
			local rule = placement.rulesById[ruleId]
			if rule and rule.groupId == groupId then
				placement.rulesById[ruleId] = nil
				table.remove(placement.ruleOrder, i)
			end
		end
		Editor.selectedGroupId = placement.groupOrder[1]
		Editor:SyncSelectedRuleToGroup(true)
		Editor:RefreshAll()
		Editor:RefreshRuntimeNow()
	end

	local function createRuleForSelectedGroup(familyId)
		local _, placement = Editor:GetContext()
		if not placement then return nil, false end
		local groupId = Editor.selectedGroupId
		if not groupId then return nil, false end

		local function addRuleToGroupFamily(targetFamilyId)
			if targetFamilyId == nil then return nil, false end
			targetFamilyId = tostring(targetFamilyId)
			local existingRuleId = findExistingRuleForGroupFamily(placement, groupId, targetFamilyId)
			if existingRuleId then return existingRuleId, false end
			local newId = HB.GetNextRuleId and HB.GetNextRuleId(placement) or tostring((#placement.ruleOrder or 0) + 1)
			placement.rulesById[newId] = HB.CreateDefaultRule and HB.CreateDefaultRule(newId, targetFamilyId, groupId)
				or { id = newId, spellFamilyId = targetFamilyId, groupId = groupId, ["not"] = false, enabled = true, appliesParty = true, appliesRaid = true }
			tinsert(placement.ruleOrder, newId)
			return newId, true
		end

		local function addManyRulesForSelectedGroup(familyIds)
			if type(familyIds) ~= "table" or #familyIds == 0 then return end
			local firstNew, firstExisting, createdAny = nil, nil, false
			for i = 1, #familyIds do
				local ruleId, created = addRuleToGroupFamily(familyIds[i])
				if ruleId then
					if created then
						createdAny = true
						if not firstNew then firstNew = ruleId end
					elseif not firstExisting then
						firstExisting = ruleId
					end
				end
			end
			Editor.selectedRuleId = firstNew or firstExisting or Editor.selectedRuleId
			Editor:RefreshAll()
			if createdAny then Editor:RefreshRuntimeNow() end
		end

		if familyId == nil then
			local familyOptions = buildFamilyOptionsForEditor()
			if #familyOptions == 0 then return end
			for i = 1, #familyOptions do
				local candidateFamilyId = familyOptions[i].value
				if findExistingRuleForGroupFamily(placement, groupId, candidateFamilyId) == nil then
					familyId = candidateFamilyId
					break
				end
			end
			if familyId == nil then return end
		end
		if type(familyId) == "table" then
			addManyRulesForSelectedGroup(familyId)
			return nil, false
		end
		local newId, created = addRuleToGroupFamily(familyId)
		if newId then
			Editor.selectedRuleId = newId
			Editor:RefreshAll()
			if created then Editor:RefreshRuntimeNow() end
		end
		return newId, created
	end

	local customSpellPopupKey = "EQOL_HBP_CUSTOM_SPELL_ID"
	local function normalizeCustomSpellFamilyId(value)
		local spellId = tonumber(value)
		if not spellId or spellId <= 0 or spellId ~= floor(spellId) then return nil, "INVALID" end

		local spellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellId)
		if type(spellName) ~= "string" or spellName == "" then return nil, "UNKNOWN" end

		local familyId
		if HB.NormalizeCustomSpellFamilyId then familyId = HB.NormalizeCustomSpellFamilyId(spellId) end
		if familyId == nil and HB.GetFamilyFromSpell then familyId = HB.GetFamilyFromSpell(spellId) end
		if familyId == nil then
			local customFamilyId = "spell:" .. tostring(spellId)
			local family = HB.ResolveFamily and HB.ResolveFamily(customFamilyId)
			familyId = family and family.id or customFamilyId
		end
		return tostring(familyId), nil
	end

	local function showCustomSpellIdPopup(message, value)
		if not StaticPopupDialogs or not StaticPopup_Show then return end
		StaticPopupDialogs[customSpellPopupKey] = StaticPopupDialogs[customSpellPopupKey]
			or {
				text = tr("UFGroupHealerBuffEditorSpellIDPrompt", "Enter a Spell ID:"),
				button1 = ACCEPT,
				button2 = CANCEL,
				hasEditBox = true,
				maxLetters = 10,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
				OnShow = function(dialog, data)
					local prompt = data and data.message or tr("UFGroupHealerBuffEditorSpellIDPrompt", "Enter a Spell ID:")
					local text = dialog.Text or dialog.text
					local editBox = dialog.EditBox or dialog.editBox or (dialog.GetEditBox and dialog:GetEditBox())
					if text then text:SetText(prompt) end
					if not editBox then return end
					if editBox.SetNumeric then editBox:SetNumeric(true) end
					editBox:SetText(data and data.value or "")
					editBox:SetFocus()
					editBox:HighlightText()
				end,
				OnAccept = function(dialog)
					local editBox = dialog.EditBox or dialog.editBox or (dialog.GetEditBox and dialog:GetEditBox())
					local input = editBox and editBox:GetText() or ""
					local familyId, reason = normalizeCustomSpellFamilyId(input)
					if not familyId then
						local errorText = reason == "UNKNOWN" and tr("UFGroupHealerBuffEditorSpellIDUnknown", "No spell was found for this Spell ID.")
							or tr("UFGroupHealerBuffEditorSpellIDInvalid", "Enter a valid Spell ID.")
						C_Timer.After(0, function() showCustomSpellIdPopup(errorText, input) end)
						return
					end

					local _, placement = Editor:GetContext()
					local groupId = Editor.selectedGroupId
					local existingRuleId = placement and groupId and findExistingRuleForGroupFamily(placement, groupId, familyId)
					if existingRuleId then
						Editor.selectedRuleId = existingRuleId
						Editor:RefreshAll()
						C_Timer.After(0, function()
							showCustomSpellIdPopup(tr("UFGroupHealerBuffEditorSpellIDDuplicate", "This spell already has a rule in the selected indicator."), input)
						end)
						return
					end
					createRuleForSelectedGroup(familyId)
				end,
				EditBoxOnEnterPressed = function(editBox)
					local dialog = editBox:GetParent()
					local acceptButton = dialog and (dialog.button1 or (dialog.Buttons and dialog.Buttons[1]))
					if acceptButton then acceptButton:Click() end
				end,
				EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
			}
		StaticPopup_Show(customSpellPopupKey, nil, nil, { message = message, value = value })
	end

	local function deleteRuleById(ruleId)
		local _, placement = Editor:GetContext()
		if not (placement and ruleId) then return end
		placement.rulesById[ruleId] = nil
		for i = #placement.ruleOrder, 1, -1 do
			if placement.ruleOrder[i] == ruleId then table.remove(placement.ruleOrder, i) end
		end
		if Editor.selectedRuleId == ruleId then Editor.selectedRuleId = getFirstRuleIdForGroup(placement, Editor.selectedGroupId) or placement.ruleOrder[1] end
		Editor:RefreshAll()
		Editor:RefreshRuntimeNow()
	end

	local function deleteSelectedRule()
		local selected = Editor.selectedRuleId
		if not selected then return end
		deleteRuleById(selected)
	end

	local ruleFamilyMenu = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
	ruleFamilyMenu.displayMode = "MENU"
	UIDropDownMenu_Initialize(ruleFamilyMenu, function(_, level, menuList)
		local buckets, classOrder = buildFamilyOptionsByClass()
		local allFamilies = buildFamilyOptionsForEditor()
		local _, placement = Editor:GetContext()
		local selectedGroupId = Editor.selectedGroupId
		local usedFamilyMap = buildUsedFamilyMapForGroup(placement, selectedGroupId, Editor._ruleMenuUsedFamilyMap)
		Editor._ruleMenuUsedFamilyMap = usedFamilyMap
		if level == 1 then
			do
				local info = UIDropDownMenu_CreateInfo()
				info.text = tr("UFGroupHealerBuffEditorAddSpellID", "Add Spell ID...")
				info.notCheckable = true
				info.func = function() showCustomSpellIdPopup() end
				UIDropDownMenu_AddButton(info, level)
			end
			if UIDropDownMenu_AddSeparator then
				UIDropDownMenu_AddSeparator(level)
			else
				local separator = UIDropDownMenu_CreateInfo()
				separator.text = " "
				separator.disabled = true
				separator.notCheckable = true
				UIDropDownMenu_AddButton(separator, level)
			end
			local allAvailableFamilyIds = {}
			for i = 1, #allFamilies do
				local familyId = allFamilies[i] and allFamilies[i].value
				if familyId ~= nil and usedFamilyMap[tostring(familyId)] == nil then allAvailableFamilyIds[#allAvailableFamilyIds + 1] = familyId end
			end
			do
				local info = UIDropDownMenu_CreateInfo()
				info.text = tr("UFGroupHealerBuffEditorAddAllSpells", "Add all spells")
				info.notCheckable = true
				info.disabled = #allAvailableFamilyIds == 0
				if #allAvailableFamilyIds > 0 then
					local batch = copyArray(allAvailableFamilyIds)
					info.func = function() createRuleForSelectedGroup(batch) end
				end
				UIDropDownMenu_AddButton(info, level)
			end
			for i = 1, #classOrder do
				local classToken = classOrder[i]
				local bucket = buckets[classToken]
				if bucket and bucket.spells and #bucket.spells > 0 then
					local hasAvailable = false
					for si = 1, #bucket.spells do
						local option = bucket.spells[si]
						if option and usedFamilyMap[tostring(option.value)] == nil then
							hasAvailable = true
							break
						end
					end
					local info = UIDropDownMenu_CreateInfo()
					info.text = bucket.label
					info.notCheckable = true
					info.hasArrow = hasAvailable
					info.disabled = not hasAvailable
					if hasAvailable then info.menuList = classToken end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		elseif level == 2 and menuList then
			local bucket = buckets[menuList]
			if not (bucket and bucket.spells) then return end
			local classAvailableFamilyIds = {}
			for i = 1, #bucket.spells do
				local option = bucket.spells[i]
				if option and usedFamilyMap[tostring(option.value)] == nil then classAvailableFamilyIds[#classAvailableFamilyIds + 1] = option.value end
			end
			do
				local info = UIDropDownMenu_CreateInfo()
				info.text = tr("UFGroupHealerBuffEditorAddAll", "Add all")
				info.notCheckable = true
				info.disabled = #classAvailableFamilyIds == 0
				if #classAvailableFamilyIds > 0 then
					local batch = copyArray(classAvailableFamilyIds)
					info.func = function() createRuleForSelectedGroup(batch) end
				end
				UIDropDownMenu_AddButton(info, level)
			end
			for i = 1, #bucket.spells do
				local option = bucket.spells[i]
				local info = UIDropDownMenu_CreateInfo()
				info.text = getDropdownOptionText(option, true)
				info.notCheckable = true
				local isUsed = usedFamilyMap[tostring(option.value)] ~= nil
				info.disabled = isUsed
				if not isUsed then info.func = function() createRuleForSelectedGroup(option.value) end end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end, "MENU")

	local groupStyleMenu = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
	groupStyleMenu.displayMode = "MENU"
	UIDropDownMenu_Initialize(groupStyleMenu, function(_, level)
		local styleOptions = buildStyleOptionsForMenu()
		for i = 1, #styleOptions do
			local option = styleOptions[i]
			local info = UIDropDownMenu_CreateInfo()
			info.text = getDropdownOptionText(option, true)
			info.notCheckable = true
			info.func = function() createGroupFromStyle(option.value) end
			UIDropDownMenu_AddButton(info, level)
		end
	end, "MENU")

	enabledCheck:SetScript("OnClick", function()
		local _, placement = Editor:GetContext()
		if not placement then return end
		placement.enabled = enabledCheck:GetChecked() == true
		Editor:RefreshRuntimeNow()
		Editor:RefreshLists()
	end)

	addGroup:SetScript("OnClick", function(self)
		if _G.UIDROPDOWNMENU_OPEN_MENU == groupStyleMenu then
			if CloseDropDownMenus then CloseDropDownMenus(1) end
			return
		end
		if ToggleDropDownMenu then
			ToggleDropDownMenu(1, nil, groupStyleMenu, self, 0, 0)
			return
		end
		local styleOptions = buildStyleOptionsForMenu()
		for i = 1, #styleOptions do
			local option = styleOptions[i]
			if option and option.value then
				createGroupFromStyle(option.value)
				return
			end
		end
	end)

	deleteGroup:SetScript("OnClick", function() deleteGroupById(Editor.selectedGroupId) end)

	groupUp:SetScript("OnClick", function()
		local _, placement = Editor:GetContext()
		if not placement then return end
		local idx = indexOf(placement.groupOrder, Editor.selectedGroupId)
		if not idx or idx <= 1 then return end
		placement.groupOrder[idx], placement.groupOrder[idx - 1] = placement.groupOrder[idx - 1], placement.groupOrder[idx]
		Editor:RefreshLists()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	groupDown:SetScript("OnClick", function()
		local _, placement = Editor:GetContext()
		if not placement then return end
		local idx = indexOf(placement.groupOrder, Editor.selectedGroupId)
		if not idx or idx >= #placement.groupOrder then return end
		placement.groupOrder[idx], placement.groupOrder[idx + 1] = placement.groupOrder[idx + 1], placement.groupOrder[idx]
		Editor:RefreshLists()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	addRule:SetScript("OnClick", function(self)
		if _G.UIDROPDOWNMENU_OPEN_MENU == ruleFamilyMenu then
			if CloseDropDownMenus then CloseDropDownMenus(1) end
			return
		end
		if ToggleDropDownMenu then
			ToggleDropDownMenu(1, nil, ruleFamilyMenu, self, 0, 0)
			return
		end
		createRuleForSelectedGroup()
	end)

	deleteRule:SetScript("OnClick", function() deleteSelectedRule() end)

	ruleUp:SetScript("OnClick", function()
		local _, placement = Editor:GetContext()
		if not placement then return end
		local selected = Editor.selectedRuleId
		local rule = selected and placement.rulesById and placement.rulesById[selected]
		if not rule then return end
		local idx = indexOf(placement.ruleOrder, selected)
		if not idx then return end
		local swapIdx = nil
		for i = idx - 1, 1, -1 do
			local ruleId = placement.ruleOrder[i]
			local candidate = ruleId and placement.rulesById and placement.rulesById[ruleId]
			if candidate and candidate.groupId == rule.groupId then
				swapIdx = i
				break
			end
		end
		if not swapIdx then return end
		placement.ruleOrder[idx], placement.ruleOrder[swapIdx] = placement.ruleOrder[swapIdx], placement.ruleOrder[idx]
		Editor:RefreshLists()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	ruleDown:SetScript("OnClick", function()
		local _, placement = Editor:GetContext()
		if not placement then return end
		local selected = Editor.selectedRuleId
		local rule = selected and placement.rulesById and placement.rulesById[selected]
		if not rule then return end
		local idx = indexOf(placement.ruleOrder, selected)
		if not idx then return end
		local swapIdx = nil
		for i = idx + 1, #placement.ruleOrder do
			local ruleId = placement.ruleOrder[i]
			local candidate = ruleId and placement.rulesById and placement.rulesById[ruleId]
			if candidate and candidate.groupId == rule.groupId then
				swapIdx = i
				break
			end
		end
		if not swapIdx then return end
		placement.ruleOrder[idx], placement.ruleOrder[swapIdx] = placement.ruleOrder[swapIdx], placement.ruleOrder[idx]
		Editor:RefreshLists()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	for i = 1, GROUP_VISIBLE_ROWS do
		local row = groupPanel.Rows[i]
		row:SetScript("OnClick", function(self)
			if not self.groupId then return end
			Editor.selectedGroupId = self.groupId
			Editor:SyncSelectedRuleToGroup(true)
			Editor:RefreshAll()
		end)
		row:SetScript("OnDragStart", function(self)
			if not self.groupId then return end
			Editor.draggingList = "groups"
			Editor.dragGroupId = self.groupId
			Editor.dragGroupTarget = nil
			self:SetAlpha(0.6)
		end)
		row:SetScript("OnDragStop", function(self)
			self:SetAlpha(1)
			if Editor.draggingList ~= "groups" then return end
			local fromId = Editor.dragGroupId
			local targetId = Editor.dragGroupTarget
			Editor.draggingList = nil
			Editor.dragGroupId = nil
			Editor.dragGroupTarget = nil
			if not fromId or not targetId or fromId == targetId then
				Editor:RefreshGroupList()
				return
			end
			local _, placement = Editor:GetContext()
			if placement and moveIdInOrder(placement.groupOrder, fromId, targetId) then
				Editor.selectedGroupId = fromId
				Editor:RefreshAll()
				Editor:RefreshRuntimeNow()
				return
			end
			Editor:RefreshGroupList()
		end)
		row:SetScript("OnEnter", function(self)
			if Editor.draggingList == "groups" and self.groupId then
				Editor.dragGroupTarget = self.groupId
				self:SetBackdropColor(0.16, 0.48, 0.24, 0.95)
				self:SetBackdropBorderColor(0.4, 0.9, 0.5, 1)
			end
		end)
		row:SetScript("OnLeave", function()
			if Editor.draggingList == "groups" then Editor:RefreshGroupList() end
		end)
		if row.DeleteButton then
			row.DeleteButton:SetScript("OnClick", function(btn)
				local parent = btn:GetParent()
				if not (parent and parent.groupId) then return end
				deleteGroupById(parent.groupId)
			end)
		end
	end

	for i = 1, RULE_VISIBLE_ROWS do
		local row = rulePanel.Rows[i]
		row:SetScript("OnClick", function(self)
			if not self.ruleId then return end
			Editor.selectedRuleId = self.ruleId
			Editor:RefreshAll()
		end)
		row:SetScript("OnDragStart", function(self)
			if not self.ruleId then return end
			Editor.draggingList = "rules"
			Editor.dragRuleId = self.ruleId
			Editor.dragRuleTarget = nil
			self:SetAlpha(0.6)
		end)
		row:SetScript("OnDragStop", function(self)
			self:SetAlpha(1)
			if Editor.draggingList ~= "rules" then return end
			local fromId = Editor.dragRuleId
			local targetId = Editor.dragRuleTarget
			Editor.draggingList = nil
			Editor.dragRuleId = nil
			Editor.dragRuleTarget = nil
			if not fromId or not targetId or fromId == targetId then
				Editor:RefreshRuleList()
				return
			end
			local _, placement = Editor:GetContext()
			local fromRule = placement and placement.rulesById and placement.rulesById[fromId]
			local targetRule = placement and placement.rulesById and placement.rulesById[targetId]
			if fromRule and targetRule and fromRule.groupId == targetRule.groupId and moveIdInOrder(placement.ruleOrder, fromId, targetId) then
				Editor.selectedRuleId = fromId
				Editor:RefreshAll()
				Editor:RefreshRuntimeNow()
				return
			end
			Editor:RefreshRuleList()
		end)
		row:SetScript("OnEnter", function(self)
			if Editor.draggingList == "rules" and self.ruleId then
				Editor.dragRuleTarget = self.ruleId
				self:SetBackdropColor(0.16, 0.48, 0.24, 0.95)
				self:SetBackdropBorderColor(0.4, 0.9, 0.5, 1)
			end
		end)
		row:SetScript("OnLeave", function()
			if Editor.draggingList == "rules" then Editor:RefreshRuleList() end
		end)
		if row.DeleteButton then
			row.DeleteButton:SetScript("OnClick", function(btn)
				local parent = btn:GetParent()
				if not (parent and parent.ruleId) then return end
				deleteRuleById(parent.ruleId)
			end)
		end
	end

	local function groupFromSelection()
		local _, placement = Editor:GetContext()
		if not placement then return nil end
		local groupId = Editor.selectedGroupId
		return groupId and placement.groupsById and placement.groupsById[groupId] or nil
	end

	local function ruleFromSelection()
		local _, placement = Editor:GetContext()
		if not placement then return nil end
		local ruleId = Editor.selectedRuleId
		return ruleId and placement.rulesById and placement.rulesById[ruleId] or nil
	end

	local function normalizeSliderValue(value, minValue, maxValue, step)
		if step and step >= 1 then
			value = roundInt(value)
		else
			value = tonumber(string.format("%.2f", value))
		end
		if minValue ~= nil and value < minValue then value = minValue end
		if maxValue ~= nil and value > maxValue then value = maxValue end
		return value
	end

	local function formatSliderValue(value, step)
		if step and step < 1 then return string.format("%.2f", tonumber(value) or 0) end
		return tostring(roundInt(value or 0))
	end

	local function getPreviewUnitFrame()
		return frame.PreviewPanel and frame.PreviewPanel.Frame and frame.PreviewPanel.Frame.UnitFrame
	end

	local function clampSelectedGroupToPreview(group)
		local preview = getPreviewUnitFrame()
		if not (group and preview) then return end
		group.x, group.y = clampGroupOffsetsForFrame(group, preview:GetWidth(), preview:GetHeight())
	end

	local function syncSliderValue(slider, valueInput, value, step)
		if slider and slider:GetValue() ~= value then
			slider._eqolSliderSync = true
			slider:SetValue(value)
			slider._eqolSliderSync = nil
		end
		if valueInput then valueInput:SetText(formatSliderValue(value, step)) end
	end

	local function syncOffsetControls(group)
		if not group then return end
		syncSliderValue(controls.XOffset, controls.XValue, group.x or 0, 1)
		syncSliderValue(controls.YOffset, controls.YValue, group.y or 0, 1)
	end

	local function updateGroupFromSlider(field, slider, valueInput, minValue, maxValue, step)
		local function applyValue(rawValue)
			if Editor._controlUpdateLock then return end
			local group = groupFromSelection()
			if not group then
				if valueInput then valueInput:SetText("") end
				return
			end
			local value = normalizeSliderValue(rawValue, minValue, maxValue, step)
			group[field] = value
			if field == "barAlpha" then
				group.color = group.color or { 1, 0.82, 0.1, 0.9 }
				group.color[4] = value
			end
			if field == "x" or field == "y" or field == "barWidth" or field == "barHeight" or field == "inset" then
				clampSelectedGroupToPreview(group)
				if field == "x" or field == "y" then
					value = field == "x" and group.x or group.y
				else
					syncOffsetControls(group)
				end
			end
			syncSliderValue(slider, valueInput, value, step)
			Editor:RefreshPreview()
			Editor:QueueRuntimeRefresh()
		end

		slider:SetScript("OnValueChanged", function(self, value)
			if self._eqolSliderSync then return end
			applyValue(value)
		end)

		if valueInput then
			local function commitInput(self)
				local raw = tonumber(self:GetText() or "")
				if raw == nil then
					local group = groupFromSelection()
					if group then
						local current = field == "x" and group.x or (field == "y" and group.y or group[field])
						if current == nil and field == "barWidth" then
							local preview = getPreviewUnitFrame()
							local width = getBarControlDimensions(group, preview and preview:GetWidth() or 0, preview and preview:GetHeight() or 0)
							current = width
						elseif current == nil and field == "barHeight" then
							local preview = getPreviewUnitFrame()
							local _, height = getBarControlDimensions(group, preview and preview:GetWidth() or 0, preview and preview:GetHeight() or 0)
							current = height
						elseif current == nil and field == "barAlpha" then
							current = group.barAlpha or (group.color and group.color[4]) or 0.9
						end
						self:SetText(formatSliderValue(current, step))
					else
						self:SetText("")
					end
					return
				end
				applyValue(raw)
			end

			valueInput:SetScript("OnEnterPressed", function(self)
				commitInput(self)
				self:ClearFocus()
			end)
			valueInput:SetScript("OnEditFocusLost", function(self) commitInput(self) end)
			valueInput:SetScript("OnEscapePressed", function(self)
				local group = groupFromSelection()
				if group then
					local current = field == "x" and group.x or (field == "y" and group.y or group[field])
					if current == nil and field == "barWidth" then
						local preview = getPreviewUnitFrame()
						local width = getBarControlDimensions(group, preview and preview:GetWidth() or 0, preview and preview:GetHeight() or 0)
						current = width
					elseif current == nil and field == "barHeight" then
						local preview = getPreviewUnitFrame()
						local _, height = getBarControlDimensions(group, preview and preview:GetWidth() or 0, preview and preview:GetHeight() or 0)
						current = height
					elseif current == nil and field == "barAlpha" then
						current = group.barAlpha or (group.color and group.color[4]) or 0.9
					end
					self:SetText(formatSliderValue(current, step))
				else
					self:SetText("")
				end
				self:ClearFocus()
			end)
		end
	end

	updateGroupFromSlider("perRow", controls.PerRow, controls.PerRowValue, 1, 20, 1)
	updateGroupFromSlider("max", controls.MaxCount, controls.MaxValue, 0, 40, 1)
	updateGroupFromSlider("spacing", controls.Spacing, controls.SpacingValue, 0, 20, 1)
	updateGroupFromSlider("size", controls.Size, controls.SizeValue, 4, 64, 1)
	updateGroupFromSlider("iconZoom", controls.IconZoom, controls.IconZoomValue, 0, 35, 1)
	updateGroupFromSlider("cooldownTextSize", controls.CooldownTextSize, controls.CooldownTextSizeValue, 6, 64, 1)
	updateGroupFromSlider("chargeTextSize", controls.ChargeTextSize, controls.ChargeTextSizeValue, 6, 64, 1)
	updateGroupFromSlider("x", controls.XOffset, controls.XValue, -200, 200, 1)
	updateGroupFromSlider("y", controls.YOffset, controls.YValue, -200, 200, 1)
	updateGroupFromSlider("barWidth", controls.BarWidth, controls.BarWidthValue, 1, BAR_DIMENSION_MAX, 1)
	updateGroupFromSlider("barHeight", controls.BarHeight, controls.BarHeightValue, 1, BAR_DIMENSION_MAX, 1)
	updateGroupFromSlider("barAlpha", controls.BarAlpha, controls.BarAlphaValue, 0, 1, 0.01)
	updateGroupFromSlider("barFrameLevelOffset", controls.BarFrameLevel, controls.BarFrameLevelValue, -20, 1000, 1)
	updateGroupFromSlider("inset", controls.Inset, controls.InsetValue, 0, 40, 1)
	updateGroupFromSlider("borderSize", controls.BorderSize, controls.BorderSizeValue, 1, 16, 1)
	updateGroupFromSlider("borderFrameLevelOffset", controls.BorderFrameLevel, controls.BorderFrameLevelValue, -20, 1000, 1)
	updateGroupFromSlider("indicatorBorderSize", controls.IndicatorBorderSize, controls.IndicatorBorderSizeValue, 1, 24, 1)
	updateGroupFromSlider("indicatorBorderOffset", controls.IndicatorBorderOffset, controls.IndicatorBorderOffsetValue, -12, 12, 1)

	controls.GroupName:SetScript("OnEnterPressed", function(self)
		local group = groupFromSelection()
		if not group then return end
		local text = self:GetText()
		if text == nil or text == "" then text = formatIndicatorName(group.id) end
		group.name = text
		self:ClearFocus()
		Editor:RefreshGroupList()
		Editor:RefreshRuleList()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)
	controls.GroupName:SetScript("OnEditFocusLost", function(self)
		local group = groupFromSelection()
		if not group then return end
		local text = self:GetText()
		if text == nil or text == "" then text = formatIndicatorName(group.id) end
		group.name = text
		Editor:RefreshGroupList()
		Editor:RefreshRuleList()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	setDropdown(controls.GroupAnchor, HB.ANCHOR_OPTIONS, nil, function(value)
		local group = groupFromSelection()
		if not group then return end
		group.anchorPoint = value
		clampSelectedGroupToPreview(group)
		Editor:RefreshGroupControls()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	controls.GroupAnchorOutside:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.anchorOutside = self:GetChecked() == true
		clampSelectedGroupToPreview(group)
		Editor:RefreshGroupControls()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	setDropdown(controls.GroupGrowth, HB.GROWTH_OPTIONS, nil, function(value)
		local group = groupFromSelection()
		if not group then return end
		group.growth = value
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	setDropdown(controls.GroupBarOrientation, HB.ORIENTATION_OPTIONS, nil, function(value)
		local group = groupFromSelection()
		if not group then return end
		group.barOrientation = value
		clampSelectedGroupToPreview(group)
		Editor:RefreshGroupControls()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	setDropdown(controls.BarStrata, buildFrameStrataOptionsForMenu(), nil, function(value)
		local group = groupFromSelection()
		if not group then return end
		group.barStrata = normalizeFrameStrataToken(value)
		Editor:RefreshGroupControls()
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	setDropdown(controls.IndicatorBorderTexture, buildBorderOptionsForMenu(), nil, function(value)
		local group = groupFromSelection()
		if not group then return end
		local texture = tostring(value or "DEFAULT")
		if texture == "" then texture = "DEFAULT" end
		group.indicatorBorderTexture = texture
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	setDropdown(controls.BorderStrata, buildFrameStrataOptionsForMenu(), nil, function(value)
		local group = groupFromSelection()
		if not group then return end
		group.borderStrata = normalizeFrameStrataToken(value)
		Editor:RefreshGroupControls()
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.IndicatorBorderColorButton:SetScript("OnClick", function(_, mouseButton)
		local group = groupFromSelection()
		if not group then return end
		if mouseButton == "RightButton" then
			group.indicatorBorderColor = { 0, 0, 0, 0.95 }
			Editor:RefreshGroupControls()
			Editor:RefreshPreview()
			Editor:QueueRuntimeRefresh()
			return
		end
		group.indicatorBorderColor = group.indicatorBorderColor or { 0, 0, 0, 0.95 }
		showColorPicker(group.indicatorBorderColor, function(r, g, b, a)
			group.indicatorBorderColor[1], group.indicatorBorderColor[2], group.indicatorBorderColor[3], group.indicatorBorderColor[4] = r, g, b, a
			Editor:RefreshGroupControls()
			Editor:RefreshPreview()
			Editor:QueueRuntimeRefresh()
		end)
	end)

	controls.ColorButton:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then return end
		local group = groupFromSelection()
		if not group then return end
		group.color = group.color or { 1, 0.82, 0.1, 0.9 }
		showColorPicker(group.color, function(r, g, b, a)
			group.color[1], group.color[2], group.color[3], group.color[4] = r, g, b, a
			if tostring(group.style or ""):upper() == "BAR" then group.barAlpha = a end
			Editor:RefreshGroupControls()
			Editor:RefreshPreview()
			Editor:QueueRuntimeRefresh()
		end)
	end)

	controls.IndicatorBorder:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.indicatorBorderEnabled = self:GetChecked() == true
		Editor:RefreshGroupControls()
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.BarFillFrame:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.barFillFrame = self:GetChecked() == true
		clampSelectedGroupToPreview(group)
		Editor:RefreshGroupControls()
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.BarDrainAnimation:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.barDrainAnimation = self:GetChecked() == true
		Editor:RefreshGroupControls()
		Editor:RefreshRuleControls()
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.BarReverseFill:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.barReverseFill = self:GetChecked() == true
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.CooldownSwipe:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.showCooldownSwipe = self:GetChecked() ~= false
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.CooldownEdge:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.showCooldownEdge = self:GetChecked() ~= false
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.CooldownBling:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.showCooldownBling = self:GetChecked() ~= false
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.HideCooldownText:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.hideCooldownText = self:GetChecked() == true
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	controls.HideChargeText:SetScript("OnClick", function(self)
		if Editor._controlUpdateLock then return end
		local group = groupFromSelection()
		if not group then
			self:SetChecked(false)
			return
		end
		group.hideChargeText = self:GetChecked() == true
		Editor:RefreshPreview()
		Editor:QueueRuntimeRefresh()
	end)

	if controls.PreviewLoop then controls.PreviewLoop:SetScript("OnClick", function(self) Editor:SetPreviewLoopEnabled(self:GetChecked() == true) end) end

	if controls.PreviewAll then controls.PreviewAll:SetScript("OnClick", function(self) Editor:SetPreviewAllEnabled(self:GetChecked() == true) end) end

	controls.RuleColorButton:SetScript("OnClick", function(_, mouseButton)
		local group = groupFromSelection()
		local rule = ruleFromSelection()
		if not (group and rule) then return end
		if not styleSupportsRuleColor(group.style) then return end
			if mouseButton == "RightButton" then
				rule.color = nil
				Editor:RefreshRuleControls()
				Editor:RefreshPreview()
				Editor:QueueRuntimeRefresh()
			return
		end
			local baseColor = rule.color or group.color or { 1, 0.82, 0.1, 0.9 }
			showColorPicker(baseColor, function(r, g, b, a)
				rule.color = { r, g, b, a }
				Editor:RefreshRuleControls()
				Editor:RefreshPreview()
				Editor:QueueRuntimeRefresh()
		end)
	end)

	local function ensureRuleDurationStep(rule, index, group)
		if not rule then return nil end
		rule.durationColorSteps = rule.durationColorSteps or {}
		local step = rule.durationColorSteps[index]
		if type(step) ~= "table" then
			step = {
				enabled = true,
				seconds = index == 1 and 20 or (index == 2 and 10 or 5),
				color = { unpackRgba(group and group.color or rule.color or { 1, 0.82, 0.1, 0.9 }) },
			}
			rule.durationColorSteps[index] = step
		end
		if step.seconds == nil then step.seconds = index == 1 and 20 or (index == 2 and 10 or 5) end
		if type(step.color) ~= "table" then step.color = { unpackRgba(rule.color or group and group.color or { 1, 0.82, 0.1, 0.9 }) } end
		return step
	end

	local function pruneRuleDurationSteps(rule)
		if not (rule and type(rule.durationColorSteps) == "table") then return end
		local hasStep = false
		for i = 1, DURATION_COLOR_STEP_MAX do
			local step = rule.durationColorSteps[i]
			if type(step) == "table" and step.enabled == true then
				hasStep = true
			else
				rule.durationColorSteps[i] = nil
			end
		end
		if not hasStep then rule.durationColorSteps = nil end
	end

	for i = 1, DURATION_COLOR_STEP_MAX do
		local stepControls = controls.DurationColorSteps[i]
		stepControls.Enabled:SetScript("OnClick", function(self)
			local group = groupFromSelection()
			local rule = ruleFromSelection()
			if not (group and rule) then return end
			local step = ensureRuleDurationStep(rule, i, group)
			step.enabled = self:GetChecked() == true
			pruneRuleDurationSteps(rule)
			Editor:RefreshRuleControls()
			Editor:RefreshPreview()
			Editor:QueueRuntimeRefresh()
		end)
		stepControls.Seconds:SetScript("OnEnterPressed", function(self)
			local group = groupFromSelection()
			local rule = ruleFromSelection()
			if not (group and rule) then return end
			local step = ensureRuleDurationStep(rule, i, group)
			local seconds = roundInt(tonumber(self:GetText()) or step.seconds or 1)
			if seconds < 1 then seconds = 1 end
			if seconds > 3600 then seconds = 3600 end
			step.seconds = seconds
			step.enabled = true
			self:SetText(tostring(seconds))
			self:ClearFocus()
			Editor:RefreshPreview()
			Editor:QueueRuntimeRefresh()
		end)
		stepControls.Seconds:SetScript("OnEditFocusLost", function(self)
			local group = groupFromSelection()
			local rule = ruleFromSelection()
			if not (group and rule) then return end
			local step = ensureRuleDurationStep(rule, i, group)
			local seconds = roundInt(tonumber(self:GetText()) or step.seconds or 1)
			if seconds < 1 then seconds = 1 end
			if seconds > 3600 then seconds = 3600 end
			step.seconds = seconds
			self:SetText(tostring(seconds))
			Editor:QueueRuntimeRefresh()
		end)
		stepControls.Seconds:SetScript("OnEscapePressed", function(self)
			local rule = ruleFromSelection()
			local step = rule and rule.durationColorSteps and rule.durationColorSteps[i]
			self:SetText(tostring((step and step.seconds) or (i == 1 and 20 or (i == 2 and 10 or 5))))
			self:ClearFocus()
		end)
		stepControls.ColorButton:SetScript("OnClick", function(_, mouseButton)
			local group = groupFromSelection()
			local rule = ruleFromSelection()
			if not (group and rule) then return end
			local step = ensureRuleDurationStep(rule, i, group)
			if mouseButton == "RightButton" then
				step.color = { unpackRgba(rule.color or group.color or { 1, 0.82, 0.1, 0.9 }) }
				Editor:RefreshRuleControls()
				Editor:RefreshPreview()
				Editor:QueueRuntimeRefresh()
				return
			end
			showColorPicker(step.color or rule.color or group.color or { 1, 0.82, 0.1, 0.9 }, function(r, g, b, a)
				step.color = { r, g, b, a }
				step.enabled = true
				Editor:RefreshRuleControls()
				Editor:RefreshPreview()
				Editor:QueueRuntimeRefresh()
			end)
		end)
	end

	controls.RuleEnabled:SetScript("OnClick", function(self)
		local rule = ruleFromSelection()
		if not rule then return end
		rule.enabled = self:GetChecked() == true
		Editor:RefreshRuleList()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	controls.RuleNot:SetScript("OnClick", function(self)
		local rule = ruleFromSelection()
		if not rule then return end
		rule["not"] = self:GetChecked() == true
		Editor:RefreshRuleControls()
		Editor:RefreshRuleList()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	controls.RuleMissingDesaturate:SetScript("OnClick", function(self)
		local rule = ruleFromSelection()
		if not rule then return end
		rule.desaturateMissing = self:GetChecked() == true
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	controls.RuleExpirationPulse:SetScript("OnClick", function(self)
		local rule = ruleFromSelection()
		if not rule then return end
		rule.expirationPulseEnabled = self:GetChecked() == true
		if rule.expirationPulseThreshold == nil then rule.expirationPulseThreshold = 3 end
		Editor:RefreshRuleControls()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	local function applyRuleExpirationPulseThreshold(value)
		local rule = ruleFromSelection()
		if not rule then return end
		value = roundInt(tonumber(value) or rule.expirationPulseThreshold or 3)
		if value < 1 then value = 1 end
		if value > 10 then value = 10 end
		rule.expirationPulseThreshold = value
		syncSliderValue(controls.RuleExpirationPulseThreshold, controls.RuleExpirationPulseThresholdValue, value, 1)
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end

	controls.RuleExpirationPulseThreshold:SetScript("OnValueChanged", function(self, value)
		if self._eqolSliderSync then return end
		applyRuleExpirationPulseThreshold(value)
	end)
	controls.RuleExpirationPulseThresholdValue:SetScript("OnEnterPressed", function(self)
		applyRuleExpirationPulseThreshold(self:GetText())
		self:ClearFocus()
	end)
	controls.RuleExpirationPulseThresholdValue:SetScript("OnEditFocusLost", function(self) applyRuleExpirationPulseThreshold(self:GetText()) end)
	controls.RuleExpirationPulseThresholdValue:SetScript("OnEscapePressed", function(self)
		local rule = ruleFromSelection()
		self:SetText(tostring((rule and rule.expirationPulseThreshold) or 3))
		self:ClearFocus()
	end)

	controls.RuleExpirationPulseCountdownOnly:SetScript("OnClick", function(self)
		local rule = ruleFromSelection()
		if not rule then return end
		rule.expirationPulseCountdownOnly = self:GetChecked() == true
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	controls.RuleExpirationPulseColorButton:SetScript("OnClick", function(_, mouseButton)
		local rule = ruleFromSelection()
		if not rule then return end
		if mouseButton == "RightButton" then
			rule.expirationPulseColor = { 1, 0.2, 0.2, 1 }
			Editor:RefreshRuleControls()
			Editor:RefreshPreview()
			Editor:RefreshRuntimeNow()
			return
		end
		local color = rule.expirationPulseColor or { 1, 0.2, 0.2, 1 }
		showColorPicker(color, function(r, g, b, a)
			rule.expirationPulseColor = { r, g, b, a }
			Editor:RefreshRuleControls()
			Editor:RefreshPreview()
			Editor:RefreshRuntimeNow()
		end)
	end)

	controls.RuleAppliesParty:SetScript("OnClick", function(self)
		local rule = ruleFromSelection()
		if not rule then return end
		rule.appliesParty = self:GetChecked() == true
		if rule.appliesParty == false and rule.appliesRaid == false then
			rule.appliesRaid = true
			controls.RuleAppliesRaid:SetChecked(true)
		end
		Editor:RefreshRuleList()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	controls.RuleAppliesRaid:SetScript("OnClick", function(self)
		local rule = ruleFromSelection()
		if not rule then return end
		rule.appliesRaid = self:GetChecked() == true
		if rule.appliesRaid == false and rule.appliesParty == false then
			rule.appliesParty = true
			controls.RuleAppliesParty:SetChecked(true)
		end
		Editor:RefreshRuleList()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	setDropdown(controls.RuleIconMode, HB.ICON_MODE_OPTIONS or {
		{ value = "ALL", label = tr("UFGroupHealerBuffIconModeAll", "Show All Active Spells") },
		{ value = "PRIORITY", label = tr("UFGroupHealerBuffIconModePriority", "Show Highest Priority Only") },
	}, nil, function(value)
		local _, placement = Editor:GetContext()
		if not placement then return end
		local groupId = Editor.selectedGroupId
		local group = groupId and placement.groupsById and placement.groupsById[groupId]
		if not group then return end
		group.iconMode = tostring(value or "ALL"):upper()
		Editor:RefreshGroupControls()
		Editor:RefreshRuleControls()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	setDropdown(controls.RuleMatch, HB.RULE_MATCH_OPTIONS or {
		{ value = "ANY", label = tr("UFGroupHealerBuffRuleMatchAny", "Require Any Spell") },
		{ value = "ALL", label = tr("UFGroupHealerBuffRuleMatchAll", "Require All Spells") },
	}, nil, function(value)
		local _, placement = Editor:GetContext()
		if not placement then return end
		local groupId = Editor.selectedGroupId
		local group = groupId and placement.groupsById and placement.groupsById[groupId]
		if not group then return end
		group.ruleMatch = tostring(value or "ANY"):upper()
		Editor:RefreshRuleControls()
		Editor:RefreshPreview()
		Editor:RefreshRuntimeNow()
	end)

	frame:SetScript("OnShow", function()
		if frame._updateGroupControlScroll then frame._updateGroupControlScroll() end
		if frame._updateRuleControlScroll then frame._updateRuleControlScroll() end
		Editor:UpdatePreviewLoopTicker()
	end)
	frame:SetScript("OnHide", function() Editor:UpdatePreviewLoopTicker() end)
	frame:SetScript("OnSizeChanged", function()
		if frame._updateGroupControlScroll then frame._updateGroupControlScroll() end
		if frame._updateRuleControlScroll then frame._updateRuleControlScroll() end
	end)
	if frame._updateGroupControlScroll then frame._updateGroupControlScroll() end
	if frame._updateRuleControlScroll then frame._updateRuleControlScroll() end

	return frame
end

function Editor:RefreshGroupList()
	local frame = self:EnsureFrame()
	local _, placement = self:GetContext()
	local rows = frame.GroupPanel.Rows
	if not placement then
		for i = 1, #rows do
			rows[i]:Hide()
		end
		if frame.GroupPanel and frame.GroupPanel.ScrollBar and frame.GroupPanel.ScrollBar.Sync then frame.GroupPanel.ScrollBar:Sync() end
		return
	end
	local order = placement.groupOrder or EMPTY
	if self.selectedGroupId == nil or indexOf(order, self.selectedGroupId) == nil then self.selectedGroupId = order[1] end
	local maxOffset = max(0, #order - GROUP_VISIBLE_ROWS)
	if (self.groupOffset or 0) > maxOffset then self.groupOffset = maxOffset end
	if (self.groupOffset or 0) < 0 then self.groupOffset = 0 end

	for i = 1, GROUP_VISIBLE_ROWS do
		local index = i + (self.groupOffset or 0)
		local row = rows[i]
		local groupId = order[index]
		local group = groupId and placement.groupsById and placement.groupsById[groupId]
		if group then
			row.groupId = groupId
			row:Show()
			if row.DeleteButton then row.DeleteButton:Show() end
			local label = string.format(tr("UFGroupHealerBuffEditorGroupRowFormat", "%d. %s  [%s]"), index, tostring(group.name or formatIndicatorName(groupId)), tostring(group.style or "ICON"))
			row.Text:SetText(label)
			if groupId == self.selectedGroupId then
				row:SetBackdropColor(0.12, 0.19, 0.3, 0.95)
				row:SetBackdropBorderColor(0.52, 0.76, 1, 1)
			else
				row:SetBackdropColor(0.07, 0.09, 0.12, 0.82)
				row:SetBackdropBorderColor(0.2, 0.26, 0.32, 0.9)
			end
		else
			row.groupId = nil
			if row.DeleteButton then row.DeleteButton:Hide() end
			row:Hide()
		end
	end
	if frame.GroupPanel and frame.GroupPanel.ScrollBar and frame.GroupPanel.ScrollBar.Sync then frame.GroupPanel.ScrollBar:Sync() end
end

function Editor:RefreshRuleList()
	local frame = self:EnsureFrame()
	local _, placement = self:GetContext()
	local rows = frame.RulePanel.Rows
	if frame.RulePanel and frame.RulePanel.Title then
		local groupLabel = (placement and self.selectedGroupId) and getGroupLabel(placement, self.selectedGroupId) or nil
		local titleFormat = tr("UFGroupHealerBuffEditorSpellRulesGroupFormat", "Spell Rules - %s")
		frame.RulePanel.Title:SetText(groupLabel and string.format(titleFormat, groupLabel) or tr("UFGroupHealerBuffEditorSpellRules", "Spell Rules"))
	end
	if not placement then
		for i = 1, #rows do
			rows[i]:Hide()
		end
		if frame.RulePanel and frame.RulePanel.ScrollBar and frame.RulePanel.ScrollBar.Sync then frame.RulePanel.ScrollBar:Sync() end
		return
	end
	local order = getVisibleRuleIds(placement, self.selectedGroupId, self._ruleScratch)
	self._ruleScratch = order
	if self.selectedRuleId and placement.rulesById and placement.rulesById[self.selectedRuleId] then
		local selectedRule = placement.rulesById[self.selectedRuleId]
		if self.selectedGroupId and selectedRule.groupId ~= self.selectedGroupId then
			self.selectedRuleId = order[1]
		elseif indexOf(order, self.selectedRuleId) == nil then
			self.selectedRuleId = order[1]
		end
	elseif self.selectedRuleId ~= nil then
		self.selectedRuleId = order[1]
	end
	local maxOffset = max(0, #order - RULE_VISIBLE_ROWS)
	if (self.ruleOffset or 0) > maxOffset then self.ruleOffset = maxOffset end
	if (self.ruleOffset or 0) < 0 then self.ruleOffset = 0 end

	for i = 1, RULE_VISIBLE_ROWS do
		local index = i + (self.ruleOffset or 0)
		local row = rows[i]
		local ruleId = order[index]
		local rule = ruleId and placement.rulesById and placement.rulesById[ruleId]
		if rule then
			row.ruleId = ruleId
			row:Show()
			if row.DeleteButton then row.DeleteButton:Show() end
			local familyLabel = getFamilyLabel(rule.spellFamilyId, true)
			local marker = rule["not"] and tr("UFGroupHealerBuffEditorRuleMarkerNot", " [NOT]") or ""
			local state = (rule.enabled ~= false) and "" or tr("UFGroupHealerBuffEditorRuleMarkerOff", " [OFF]")
			local appliesParty = rule.appliesParty ~= false
			local appliesRaid = rule.appliesRaid ~= false
			local scope = tr("UFGroupHealerBuffEditorScopeMarkerNone", " [NONE]")
			if appliesParty and appliesRaid then
				scope = tr("UFGroupHealerBuffEditorScopeMarkerPartyRaid", " [P/R]")
			elseif appliesParty then
				scope = tr("UFGroupHealerBuffEditorScopeMarkerParty", " [P]")
			elseif appliesRaid then
				scope = tr("UFGroupHealerBuffEditorScopeMarkerRaid", " [R]")
			end
			local label = string.format(tr("UFGroupHealerBuffEditorRuleRowFormat", "%d. %s%s%s%s"), index, familyLabel, scope, marker, state)
			row.Text:SetText(label)
			if ruleId == self.selectedRuleId then
				row:SetBackdropColor(0.12, 0.19, 0.3, 0.95)
				row:SetBackdropBorderColor(0.52, 0.76, 1, 1)
			else
				row:SetBackdropColor(0.07, 0.09, 0.12, 0.82)
				row:SetBackdropBorderColor(0.2, 0.26, 0.32, 0.9)
			end
		else
			row.ruleId = nil
			if row.DeleteButton then row.DeleteButton:Hide() end
			row:Hide()
		end
	end
	if frame.RulePanel and frame.RulePanel.ScrollBar and frame.RulePanel.ScrollBar.Sync then frame.RulePanel.ScrollBar:Sync() end
end

function Editor:RefreshLists()
	self:RefreshGroupList()
	self:RefreshRuleList()
end

function Editor:RefreshRuleControls()
	local frame = self:EnsureFrame()
	local controls = frame.Controls
	local _, placement = self:GetContext()
	self:SyncSelectedRuleToGroup(false)
	local rule = placement and self.selectedRuleId and placement.rulesById and placement.rulesById[self.selectedRuleId] or nil
	local selectedGroup = placement and self.selectedGroupId and placement.groupsById and placement.groupsById[self.selectedGroupId] or nil
	local selectedGroupStyle = tostring(selectedGroup and selectedGroup.style or "")
	local showIconRuleMode = selectedGroupStyle == "ICON" or selectedGroupStyle == "SQUARE"
	local showMissingDesaturate = selectedGroupStyle == "ICON" and rule ~= nil and rule["not"] == true
	local showExpirationPulse = showIconRuleMode and rule ~= nil and rule["not"] ~= true
	local showTintRuleMatch = selectedGroupStyle == "TINT"
	local showRuleColor = styleSupportsRuleColor(selectedGroupStyle)
	local showDurationColorSteps = showRuleColor and rule ~= nil and rule["not"] ~= true
	local showBarDrainInfo = selectedGroupStyle == "BAR" and selectedGroup and selectedGroup.barDrainAnimation == true
	local iconModeOptions = HB.ICON_MODE_OPTIONS
		or {
			{ value = "ALL", label = tr("UFGroupHealerBuffIconModeAll", "Show All Active Spells") },
			{ value = "PRIORITY", label = tr("UFGroupHealerBuffIconModePriority", "Show Highest Priority Only") },
		}
	local ruleMatchOptions = HB.RULE_MATCH_OPTIONS
		or {
			{ value = "ANY", label = tr("UFGroupHealerBuffRuleMatchAny", "Require Any Spell") },
			{ value = "ALL", label = tr("UFGroupHealerBuffRuleMatchAll", "Require All Spells") },
		}

	setControlVisible(controls.RuleIconModeLabel, showIconRuleMode)
	setControlVisible(controls.RuleIconMode, showIconRuleMode)
	setControlEnabled(controls.RuleIconMode, showIconRuleMode)
	if showIconRuleMode then setDropdown(controls.RuleIconMode, iconModeOptions, tostring(selectedGroup.iconMode or "ALL"):upper(), controls.RuleIconMode._eqolOnSelect) end

	setControlVisible(controls.RuleMatchLabel, showTintRuleMatch)
	setControlVisible(controls.RuleMatch, showTintRuleMatch)
	setControlEnabled(controls.RuleMatch, showTintRuleMatch)
	if showTintRuleMatch then setDropdown(controls.RuleMatch, ruleMatchOptions, tostring(selectedGroup.ruleMatch or "ANY"):upper(), controls.RuleMatch._eqolOnSelect) end

	controls.RuleMissingDesaturate:ClearAllPoints()
	if showMissingDesaturate then controls.RuleMissingDesaturate:SetPoint("TOPLEFT", controls.RuleNot, "BOTTOMLEFT", 16, -6) end
	controls.RuleExpirationPulse:ClearAllPoints()
	if showMissingDesaturate then
		controls.RuleExpirationPulse:SetPoint("TOPLEFT", controls.RuleMissingDesaturate, "BOTTOMLEFT", -16, -6)
	else
		controls.RuleExpirationPulse:SetPoint("TOPLEFT", controls.RuleNot, "BOTTOMLEFT", 0, -6)
	end
	controls.RuleExpirationPulseThresholdLabel:ClearAllPoints()
	controls.RuleExpirationPulseThresholdLabel:SetPoint("TOPLEFT", controls.RuleExpirationPulse, "BOTTOMLEFT", 4, -18)
	controls.RuleExpirationPulseThreshold:ClearAllPoints()
	controls.RuleExpirationPulseThreshold:SetPoint("TOPLEFT", controls.RuleExpirationPulseThresholdLabel, "TOPRIGHT", 10, 8)
	controls.RuleExpirationPulseThresholdValue:ClearAllPoints()
	controls.RuleExpirationPulseThresholdValue:SetPoint("LEFT", controls.RuleExpirationPulseThreshold, "RIGHT", 12, 0)
	controls.RuleExpirationPulseColorLabel:ClearAllPoints()
	controls.RuleExpirationPulseColorLabel:SetPoint("TOPLEFT", controls.RuleExpirationPulseThresholdLabel, "BOTTOMLEFT", -4, -14)
	controls.RuleExpirationPulseColorButton:ClearAllPoints()
	controls.RuleExpirationPulseColorButton:SetPoint("LEFT", controls.RuleExpirationPulseColorLabel, "RIGHT", 10, 0)
	controls.RuleExpirationPulseCountdownOnly:ClearAllPoints()
	controls.RuleExpirationPulseCountdownOnly:SetPoint("TOPLEFT", controls.RuleExpirationPulseColorLabel, "BOTTOMLEFT", -4, -10)
	controls.RuleAppliesParty:ClearAllPoints()
	if showExpirationPulse and rule and rule.expirationPulseEnabled == true then
		controls.RuleAppliesParty:SetPoint("TOPLEFT", controls.RuleExpirationPulseCountdownOnly, "BOTTOMLEFT", 0, -6)
	elseif showExpirationPulse then
		controls.RuleAppliesParty:SetPoint("TOPLEFT", controls.RuleExpirationPulse, "BOTTOMLEFT", 0, -6)
	elseif showMissingDesaturate then
		controls.RuleAppliesParty:SetPoint("TOPLEFT", controls.RuleMissingDesaturate, "BOTTOMLEFT", -16, -6)
	else
		controls.RuleAppliesParty:SetPoint("TOPLEFT", controls.RuleNot, "BOTTOMLEFT", 0, -6)
	end
	controls.RuleAppliesRaid:ClearAllPoints()
	controls.RuleAppliesRaid:SetPoint("TOPLEFT", controls.RuleAppliesParty, "BOTTOMLEFT", 0, -6)

	controls.RuleColorLabel:ClearAllPoints()
	if showTintRuleMatch then
		controls.RuleColorLabel:SetPoint("TOPLEFT", controls.RuleMatchLabel, "BOTTOMLEFT", 0, -16)
	elseif showIconRuleMode then
		controls.RuleColorLabel:SetPoint("TOPLEFT", controls.RuleIconModeLabel, "BOTTOMLEFT", 0, -16)
	else
		controls.RuleColorLabel:SetPoint("TOPLEFT", controls.RuleAppliesRaid, "BOTTOMLEFT", 0, -14)
	end
	controls.RuleColorButton:ClearAllPoints()
	controls.RuleColorButton:SetPoint("LEFT", controls.RuleColorLabel, "RIGHT", 10, 0)
	setControlVisible(controls.RuleColorLabel, showRuleColor)
	setControlVisible(controls.RuleColorButton, showRuleColor)
	setControlEnabled(controls.RuleColorButton, showRuleColor and rule ~= nil)
	if showRuleColor then
		local baseColor = (rule and rule.color) or (selectedGroup and selectedGroup.color) or { 1, 0.82, 0.1, 0.9 }
		setColorPreview(controls.RuleColorButton, baseColor)
		if rule and rule.color then
			controls.RuleColorButton:SetBackdropBorderColor(0.45, 0.78, 0.52, 1)
		else
			controls.RuleColorButton:SetBackdropBorderColor(0.28, 0.33, 0.4, 1)
		end
	end

	local lastDurationStepControl = nil
	for i = 1, DURATION_COLOR_STEP_MAX do
		local stepControls = controls.DurationColorSteps and controls.DurationColorSteps[i]
		if stepControls then
			local step = rule and rule.durationColorSteps and rule.durationColorSteps[i] or nil
			stepControls.Enabled:ClearAllPoints()
			if i == 1 then
				stepControls.Enabled:SetPoint("TOPLEFT", controls.RuleColorLabel, "BOTTOMLEFT", 0, -8)
			else
				stepControls.Enabled:SetPoint("TOPLEFT", controls.DurationColorSteps[i - 1].Enabled, "BOTTOMLEFT", 0, -8)
			end
			stepControls.Enabled:SetChecked(step and step.enabled == true)
			stepControls.Seconds:SetText(tostring((step and step.seconds) or (i == 1 and 20 or (i == 2 and 10 or 5))))
			setColorPreview(stepControls.ColorButton, (step and step.color) or (rule and rule.color) or (selectedGroup and selectedGroup.color) or { 1, 0.82, 0.1, 0.9 })
			setControlVisible(stepControls.Enabled, showDurationColorSteps)
			setControlVisible(stepControls.Seconds, showDurationColorSteps)
			setControlVisible(stepControls.SecondsLabel, showDurationColorSteps)
			setControlVisible(stepControls.ColorButton, showDurationColorSteps)
			setControlEnabled(stepControls.Enabled, showDurationColorSteps)
			setControlEnabled(stepControls.Seconds, showDurationColorSteps and step and step.enabled == true)
			setControlEnabled(stepControls.ColorButton, showDurationColorSteps and step and step.enabled == true)
			if showDurationColorSteps then lastDurationStepControl = stepControls.Enabled end
		end
	end

	controls.RuleInfo:ClearAllPoints()
	if lastDurationStepControl then
		controls.RuleInfo:SetPoint("TOPLEFT", lastDurationStepControl, "BOTTOMLEFT", 0, -16)
	elseif showRuleColor then
		controls.RuleInfo:SetPoint("TOPLEFT", controls.RuleColorLabel, "BOTTOMLEFT", 0, -20)
	elseif showTintRuleMatch then
		controls.RuleInfo:SetPoint("TOPLEFT", controls.RuleMatchLabel, "BOTTOMLEFT", 0, -12)
	elseif showIconRuleMode then
		controls.RuleInfo:SetPoint("TOPLEFT", controls.RuleIconModeLabel, "BOTTOMLEFT", 0, -12)
	else
		controls.RuleInfo:SetPoint("TOPLEFT", controls.RuleAppliesRaid, "BOTTOMLEFT", 0, -12)
	end
	controls.RuleInfo:SetPoint("RIGHT", frame.SettingsPanel.RuleControlContent, "RIGHT", -4, 0)

	controls.RuleEnabled:SetChecked(rule and rule.enabled ~= false)
	controls.RuleNot:SetChecked(rule and rule["not"] == true)
	controls.RuleMissingDesaturate:SetChecked(rule and rule.desaturateMissing == true)
	controls.RuleExpirationPulse:SetChecked(rule and rule.expirationPulseEnabled == true)
	local pulseThreshold = roundInt(tonumber(rule and rule.expirationPulseThreshold) or 3)
	if pulseThreshold < 1 then pulseThreshold = 1 end
	if pulseThreshold > 10 then pulseThreshold = 10 end
	controls.RuleExpirationPulseThreshold:SetValue(pulseThreshold)
	controls.RuleExpirationPulseThresholdValue:SetText(tostring(pulseThreshold))
	controls.RuleExpirationPulseCountdownOnly:SetChecked(rule and rule.expirationPulseCountdownOnly == true)
	setColorPreview(controls.RuleExpirationPulseColorButton, (rule and rule.expirationPulseColor) or { 1, 0.2, 0.2, 1 })
	controls.RuleAppliesParty:SetChecked(rule and rule.appliesParty ~= false)
	controls.RuleAppliesRaid:SetChecked(rule and rule.appliesRaid ~= false)
	setControlEnabled(controls.RuleEnabled, rule ~= nil)
	setControlEnabled(controls.RuleNot, rule ~= nil)
	setControlVisible(controls.RuleMissingDesaturate, showMissingDesaturate)
	setControlEnabled(controls.RuleMissingDesaturate, showMissingDesaturate and rule ~= nil)
	setControlVisible(controls.RuleExpirationPulse, showExpirationPulse)
	setControlEnabled(controls.RuleExpirationPulse, showExpirationPulse and rule ~= nil)
	setControlVisible(controls.RuleExpirationPulseThresholdLabel, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlVisible(controls.RuleExpirationPulseThreshold, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlVisible(controls.RuleExpirationPulseThresholdValue, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlEnabled(controls.RuleExpirationPulseThreshold, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlEnabled(controls.RuleExpirationPulseThresholdValue, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlVisible(controls.RuleExpirationPulseColorLabel, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlVisible(controls.RuleExpirationPulseColorButton, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlEnabled(controls.RuleExpirationPulseColorButton, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlVisible(controls.RuleExpirationPulseCountdownOnly, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlEnabled(controls.RuleExpirationPulseCountdownOnly, showExpirationPulse and rule and rule.expirationPulseEnabled == true)
	setControlEnabled(controls.RuleAppliesParty, rule ~= nil)
	setControlEnabled(controls.RuleAppliesRaid, rule ~= nil)
	setControlEnabled(frame.RulePanel and frame.RulePanel.AddButton, self.selectedGroupId ~= nil)
	if controls.RuleInfo then
		local groupLabel = placement and self.selectedGroupId and getGroupLabel(placement, self.selectedGroupId) or tr("UFGroupHealerBuffEditorSelectedIndicator", "selected indicator")
		if showTintRuleMatch and showRuleColor then
			controls.RuleInfo:SetText(
				string.format(
					tr(
						"UFGroupHealerBuffEditorRuleInfoTintColor",
						"Showing rules for %s. Scope is set per rule (Party/Raid). Tint can require any or all active spells. When multiple rules are active, color follows the first matching rule in this list. Spell Color overrides are per rule (right click to reset)."
					),
					groupLabel
				)
			)
		elseif showRuleColor and showBarDrainInfo then
			controls.RuleInfo:SetText(
				string.format(
						tr(
							"UFGroupHealerBuffEditorRuleInfoBarDrainColor",
							"Showing rules for %s. Scope is set per rule (Party/Raid). Color follows the first active rule in this list. Duration Color steps can override the color by remaining aura time. Drain animation follows the first active timed aura in this list. Spell Color overrides are per rule (right click to reset)."
					),
					groupLabel
				)
			)
		elseif showTintRuleMatch then
			controls.RuleInfo:SetText(
				string.format(tr("UFGroupHealerBuffEditorRuleInfoTint", "Showing rules for %s. Scope is set per rule (Party/Raid). Tint can require any or all active spells."), groupLabel)
			)
		elseif showRuleColor then
			controls.RuleInfo:SetText(
				string.format(
						tr(
							"UFGroupHealerBuffEditorRuleInfoSquare",
							"Showing rules for %s. Scope is set per rule (Party/Raid). Priority follows the rule order in this list. Duration Color steps can override the color by remaining aura time. Spell Color overrides are per rule (right click to reset)."
					),
					groupLabel
				)
			)
		elseif showIconRuleMode then
			controls.RuleInfo:SetText(
				string.format(tr("UFGroupHealerBuffEditorRuleInfoIcon", "Showing rules for %s. Scope is set per rule (Party/Raid). Priority follows the rule order in this list."), groupLabel)
			)
		elseif showBarDrainInfo then
			controls.RuleInfo:SetText(
				string.format(
					tr("UFGroupHealerBuffEditorRuleInfoBarDrain", "Showing rules for %s. Scope is set per rule (Party/Raid). Drain animation follows the first active timed aura in this list."),
					groupLabel
				)
			)
		else
			controls.RuleInfo:SetText(string.format(tr("UFGroupHealerBuffEditorRuleInfoDefault", "Showing rules for %s. Scope is set per rule (Party/Raid). Add via +, remove via x."), groupLabel))
		end
	end
	if frame.SettingsPanel and frame.SettingsPanel.RuleControlContent then
		local content = frame.SettingsPanel.RuleControlContent
		local top = controls.RuleEnabled and controls.RuleEnabled.GetTop and controls.RuleEnabled:GetTop()
		local bottom = controls.RuleInfo and controls.RuleInfo.GetBottom and controls.RuleInfo:GetBottom()
		local height = 260
		if top and bottom then height = (top - bottom) + 28 end
		if height < 260 then height = 260 end
		content:SetHeight(height)
	end
	if frame._updateRuleControlScroll then frame._updateRuleControlScroll() end
end

function Editor:RefreshGroupControls()
	local frame = self:EnsureFrame()
	local controls = frame.Controls
	local cfg, placement = self:GetContext()
	local group = placement and self.selectedGroupId and placement.groupsById and placement.groupsById[self.selectedGroupId] or nil
	local selectedGroupId = group and group.id or nil
	local groupSelectionChanged = self._lastGroupControlGroupId ~= selectedGroupId
	local ac = cfg and cfg.auras and cfg.auras.buff or EMPTY

	local function setFieldState(label, control, visible, enabled)
		setControlVisible(label, visible)
		setControlVisible(control, visible)
		setControlEnabled(control, enabled and visible)
	end

	local function setSliderState(label, slider, valueText, visible, enabled)
		setControlVisible(label, visible)
		setControlVisible(slider, visible)
		setControlVisible(valueText, visible)
		setControlEnabled(slider, enabled and visible)
		setControlEnabled(valueText, enabled and visible)
	end

	local function setColorState(visible, enabled)
		setControlVisible(controls.ColorLabel, visible)
		setControlVisible(controls.ColorButton, visible)
		setControlEnabled(controls.ColorButton, enabled and visible)
	end

	local function setIndicatorBorderColorState(visible, enabled)
		setControlVisible(controls.IndicatorBorderColorLabel, visible)
		setControlVisible(controls.IndicatorBorderColorButton, visible)
		setControlEnabled(controls.IndicatorBorderColorButton, enabled and visible)
	end

	local function setCheckState(control, visible, enabled, checked)
		setControlVisible(control, visible)
		setControlEnabled(control, enabled and visible)
		if control and control.SetChecked then control:SetChecked(checked == true) end
	end

	self._controlUpdateLock = true
	setControlVisible(controls.GroupStyleLabel, false)
	setControlVisible(controls.GroupStyleValue, false)
	if group then
		local style = tostring(group.style or "ICON"):upper()
		group.iconMode = tostring(group.iconMode or "ALL"):upper()
		local isPriorityIconMode = (style == "ICON" or style == "SQUARE") and group.iconMode == "PRIORITY"
		local showBar = style == "BAR"
		local showBarFillFrame = showBar
		local showBarDimensions = showBar and group.barFillFrame ~= true
		local showAnchor = style ~= "TINT" and not (showBar and group.barFillFrame == true)
			local showGrowth = (style == "ICON" or style == "SQUARE") and not isPriorityIconMode
			local showGrid = showGrowth
			local showSize = style == "ICON" or style == "SQUARE"
			local showIconZoom = style == "ICON"
			local showOffsets = style ~= "TINT" and not (showBar and group.barFillFrame == true)
		local showInset = style == "BAR" or style == "BORDER"
		local showBorder = style == "BORDER"
		local showColor = style == "SQUARE" or style == "BAR" or style == "BORDER" or style == "TINT"
		local showBarAlpha = showBar
		local showBarDrainAnimation = style == "BAR"
		local showBarReverseFill = style == "BAR" and group.barDrainAnimation == true
		local showCooldownSwipe = style == "ICON" or style == "SQUARE"
		local showCooldownDrawOptions = style == "ICON" or style == "SQUARE"
		local showTextSizeOverrides = style == "ICON" or style == "SQUARE"
		local showIndicatorBorder = style == "ICON" or style == "SQUARE"

		controls.GroupName:SetText(group.name or "")
		setDropdown(controls.GroupAnchor, HB.ANCHOR_OPTIONS, group.anchorPoint or "CENTER", controls.GroupAnchor._eqolOnSelect)
		controls.GroupAnchorOutside:SetChecked(group.anchorOutside == true)
		setDropdown(controls.GroupGrowth, HB.GROWTH_OPTIONS, group.growth or "RIGHTDOWN", controls.GroupGrowth._eqolOnSelect)
		setDropdown(controls.GroupBarOrientation, HB.ORIENTATION_OPTIONS, group.barOrientation or "HORIZONTAL", controls.GroupBarOrientation._eqolOnSelect)

		local preview = frame.PreviewPanel and frame.PreviewPanel.Frame and frame.PreviewPanel.Frame.UnitFrame
		if preview then
			group.x, group.y = clampGroupOffsetsForFrame(group, preview:GetWidth(), preview:GetHeight())
		end

		controls.PerRow:SetValue(group.perRow or 3)
		controls.PerRowValue:SetText(tostring(group.perRow or 3))
		controls.MaxCount:SetValue(group.max or 3)
		controls.MaxValue:SetText(tostring(group.max or 3))
		controls.Spacing:SetValue(group.spacing or 0)
		controls.SpacingValue:SetText(tostring(group.spacing or 0))
		controls.Size:SetValue(group.size or 16)
		controls.SizeValue:SetText(tostring(group.size or 16))
		local iconZoom = group.iconZoom
		if addon.IconShape and addon.IconShape.NormalizeIconZoom then
			iconZoom = addon.IconShape.NormalizeIconZoom(iconZoom)
		else
			iconZoom = roundInt(tonumber(iconZoom) or 0)
			if iconZoom < 0 then iconZoom = 0 end
			if iconZoom > 35 then iconZoom = 35 end
		end
		group.iconZoom = iconZoom
		controls.IconZoom:SetValue(iconZoom)
		controls.IconZoomValue:SetText(tostring(iconZoom))

		local cooldownTextSize = tonumber(group.cooldownTextSize)
		if cooldownTextSize == nil then cooldownTextSize = tonumber(ac.cooldownFontSize) or 12 end
		if cooldownTextSize < 6 then cooldownTextSize = 6 end
		if cooldownTextSize > 64 then cooldownTextSize = 64 end
		cooldownTextSize = roundInt(cooldownTextSize)
		controls.CooldownTextSize:SetValue(cooldownTextSize)
		controls.CooldownTextSizeValue:SetText(tostring(cooldownTextSize))

		local chargeTextSize = tonumber(group.chargeTextSize)
		if chargeTextSize == nil then chargeTextSize = tonumber(ac.countFontSize) or 14 end
		if chargeTextSize < 6 then chargeTextSize = 6 end
		if chargeTextSize > 64 then chargeTextSize = 64 end
		chargeTextSize = roundInt(chargeTextSize)
		controls.ChargeTextSize:SetValue(chargeTextSize)
		controls.ChargeTextSizeValue:SetText(tostring(chargeTextSize))

		controls.XOffset:SetValue(group.x or 0)
		controls.XValue:SetText(tostring(group.x or 0))
		controls.YOffset:SetValue(group.y or 0)
		controls.YValue:SetText(tostring(group.y or 0))
		local barWidth, barHeight = getBarControlDimensions(group, preview and preview:GetWidth() or 0, preview and preview:GetHeight() or 0)
		controls.BarWidth:SetValue(barWidth)
		controls.BarWidthValue:SetText(tostring(barWidth))
		controls.BarHeight:SetValue(barHeight)
		controls.BarHeightValue:SetText(tostring(barHeight))
		local barAlpha = tonumber(group.barAlpha)
		if barAlpha == nil then barAlpha = tonumber(group.color and group.color[4]) or 0.9 end
		if barAlpha < 0 then barAlpha = 0 elseif barAlpha > 1 then barAlpha = 1 end
		controls.BarAlpha:SetValue(barAlpha)
		controls.BarAlphaValue:SetText(string.format("%.2f", barAlpha))
		group.barStrata = normalizeFrameStrataToken(group.barStrata)
		local barFrameLevel = roundInt(tonumber(group.barFrameLevelOffset) or 3)
		if barFrameLevel < -20 then barFrameLevel = -20 end
		if barFrameLevel > 1000 then barFrameLevel = 1000 end
		group.barFrameLevelOffset = barFrameLevel
		setDropdown(controls.BarStrata, buildFrameStrataOptionsForMenu(), group.barStrata or "", controls.BarStrata._eqolOnSelect)
		controls.BarFrameLevel:SetValue(barFrameLevel)
		controls.BarFrameLevelValue:SetText(tostring(barFrameLevel))
		controls.Inset:SetValue(group.inset or 0)
		controls.InsetValue:SetText(tostring(group.inset or 0))
		controls.BorderSize:SetValue(group.borderSize or 2)
		controls.BorderSizeValue:SetText(tostring(group.borderSize or 2))
		group.borderStrata = normalizeFrameStrataToken(group.borderStrata)
		local borderFrameLevel = roundInt(tonumber(group.borderFrameLevelOffset) or 4)
		if borderFrameLevel < -20 then borderFrameLevel = -20 end
		if borderFrameLevel > 1000 then borderFrameLevel = 1000 end
		group.borderFrameLevelOffset = borderFrameLevel
		setDropdown(controls.BorderStrata, buildFrameStrataOptionsForMenu(), group.borderStrata or "", controls.BorderStrata._eqolOnSelect)
		controls.BorderFrameLevel:SetValue(borderFrameLevel)
		controls.BorderFrameLevelValue:SetText(tostring(borderFrameLevel))

		if group.indicatorBorderEnabled == nil then group.indicatorBorderEnabled = false end
		local borderTexture = tostring(group.indicatorBorderTexture or "DEFAULT")
		if borderTexture == "" then borderTexture = "DEFAULT" end
		group.indicatorBorderTexture = borderTexture
		local indicatorBorderSize = roundInt(tonumber(group.indicatorBorderSize) or 1)
		if indicatorBorderSize < 1 then indicatorBorderSize = 1 end
		if indicatorBorderSize > 24 then indicatorBorderSize = 24 end
		group.indicatorBorderSize = indicatorBorderSize
		local indicatorBorderOffset = roundInt(tonumber(group.indicatorBorderOffset) or 0)
		if indicatorBorderOffset < -12 then indicatorBorderOffset = -12 end
		if indicatorBorderOffset > 12 then indicatorBorderOffset = 12 end
		group.indicatorBorderOffset = indicatorBorderOffset
		local borderColor = group.indicatorBorderColor
		if type(borderColor) ~= "table" then borderColor = { 0, 0, 0, 0.95 } end
		group.indicatorBorderColor = {
			tonumber(borderColor[1]) or 0,
			tonumber(borderColor[2]) or 0,
			tonumber(borderColor[3]) or 0,
			tonumber(borderColor[4]) or 0.95,
		}
		setDropdown(controls.IndicatorBorderTexture, buildBorderOptionsForMenu(), group.indicatorBorderTexture, controls.IndicatorBorderTexture._eqolOnSelect)
		controls.IndicatorBorderSize:SetValue(indicatorBorderSize)
		controls.IndicatorBorderSizeValue:SetText(tostring(indicatorBorderSize))
		controls.IndicatorBorderOffset:SetValue(indicatorBorderOffset)
		controls.IndicatorBorderOffsetValue:SetText(tostring(indicatorBorderOffset))
		setColorPreview(controls.IndicatorBorderColorButton, group.indicatorBorderColor)

		group.color = group.color or { 1, 0.82, 0.1, 0.9 }
		group.barDrainAnimation = group.barDrainAnimation == true
		group.barFillFrame = group.barFillFrame == true
		group.barReverseFill = group.barReverseFill == true
		if group.showCooldownSwipe == nil then group.showCooldownSwipe = true end
		if group.showCooldownEdge == nil then group.showCooldownEdge = true end
		if group.showCooldownBling == nil then group.showCooldownBling = true end
		if group.hideCooldownText == nil then group.hideCooldownText = false end
		if group.hideChargeText == nil then group.hideChargeText = false end
		setColorPreview(controls.ColorButton, {
			group.color[1] or 1,
			group.color[2] or 1,
			group.color[3] or 1,
			group.barAlpha ~= nil and barAlpha or (group.color[4] or 0.9),
		})

		setControlEnabled(controls.GroupName, true)
		setFieldState(controls.GroupAnchorLabel, controls.GroupAnchor, showAnchor, true)
		setCheckState(controls.GroupAnchorOutside, showAnchor, true, group.anchorOutside == true)
		setFieldState(controls.GroupGrowthLabel, controls.GroupGrowth, showGrowth, true)
		setFieldState(controls.GroupBarOrientationLabel, controls.GroupBarOrientation, showBar, true)
		setSliderState(controls.PerRowLabel, controls.PerRow, controls.PerRowValue, showGrid, true)
		setSliderState(controls.MaxLabel, controls.MaxCount, controls.MaxValue, showGrid, true)
		setSliderState(controls.SpacingLabel, controls.Spacing, controls.SpacingValue, showGrid, true)
		setSliderState(controls.SizeLabel, controls.Size, controls.SizeValue, showSize, true)
		setSliderState(controls.IconZoomLabel, controls.IconZoom, controls.IconZoomValue, showIconZoom, true)
		setSliderState(controls.CooldownTextSizeLabel, controls.CooldownTextSize, controls.CooldownTextSizeValue, showTextSizeOverrides, true)
		setSliderState(controls.ChargeTextSizeLabel, controls.ChargeTextSize, controls.ChargeTextSizeValue, showTextSizeOverrides, true)
		setSliderState(controls.XLabel, controls.XOffset, controls.XValue, showOffsets, true)
		setSliderState(controls.YLabel, controls.YOffset, controls.YValue, showOffsets, true)
		setSliderState(controls.BarWidthLabel, controls.BarWidth, controls.BarWidthValue, showBarDimensions, true)
		setSliderState(controls.BarHeightLabel, controls.BarHeight, controls.BarHeightValue, showBarDimensions, true)
		setSliderState(controls.BarAlphaLabel, controls.BarAlpha, controls.BarAlphaValue, showBarAlpha, true)
		setFieldState(controls.BarStrataLabel, controls.BarStrata, showBar, true)
		setSliderState(controls.BarFrameLevelLabel, controls.BarFrameLevel, controls.BarFrameLevelValue, showBar, true)
		setSliderState(controls.InsetLabel, controls.Inset, controls.InsetValue, showInset, true)
		setSliderState(controls.BorderSizeLabel, controls.BorderSize, controls.BorderSizeValue, showBorder, true)
		setFieldState(controls.BorderStrataLabel, controls.BorderStrata, showBorder, true)
		setSliderState(controls.BorderFrameLevelLabel, controls.BorderFrameLevel, controls.BorderFrameLevelValue, showBorder, true)
		setCheckState(controls.IndicatorBorder, showIndicatorBorder, true, group.indicatorBorderEnabled == true)
		setFieldState(controls.IndicatorBorderTextureLabel, controls.IndicatorBorderTexture, showIndicatorBorder, group.indicatorBorderEnabled == true)
		setSliderState(controls.IndicatorBorderSizeLabel, controls.IndicatorBorderSize, controls.IndicatorBorderSizeValue, showIndicatorBorder, group.indicatorBorderEnabled == true)
		setSliderState(controls.IndicatorBorderOffsetLabel, controls.IndicatorBorderOffset, controls.IndicatorBorderOffsetValue, showIndicatorBorder, group.indicatorBorderEnabled == true)
		setIndicatorBorderColorState(showIndicatorBorder, group.indicatorBorderEnabled == true)
		setColorState(showColor, true)
		setCheckState(controls.BarFillFrame, showBarFillFrame, true, group.barFillFrame == true)
		setCheckState(controls.BarDrainAnimation, showBarDrainAnimation, true, group.barDrainAnimation == true)
		setCheckState(controls.BarReverseFill, showBarReverseFill, true, group.barReverseFill == true)
		setCheckState(controls.CooldownSwipe, showCooldownSwipe, true, group.showCooldownSwipe ~= false)
		setCheckState(controls.CooldownEdge, showCooldownDrawOptions, true, group.showCooldownEdge ~= false)
		setCheckState(controls.CooldownBling, showCooldownDrawOptions, true, group.showCooldownBling ~= false)
		setCheckState(controls.HideCooldownText, showCooldownDrawOptions, true, group.hideCooldownText == true)
		setCheckState(controls.HideChargeText, showCooldownDrawOptions, true, group.hideChargeText == true)
	else
		controls.GroupName:SetText("")
		setControlEnabled(controls.GroupName, false)
		setFieldState(controls.GroupAnchorLabel, controls.GroupAnchor, false, false)
		setCheckState(controls.GroupAnchorOutside, false, false, false)
		setFieldState(controls.GroupGrowthLabel, controls.GroupGrowth, false, false)
		setFieldState(controls.GroupBarOrientationLabel, controls.GroupBarOrientation, false, false)
		setSliderState(controls.PerRowLabel, controls.PerRow, controls.PerRowValue, false, false)
		setSliderState(controls.MaxLabel, controls.MaxCount, controls.MaxValue, false, false)
		setSliderState(controls.SpacingLabel, controls.Spacing, controls.SpacingValue, false, false)
		setSliderState(controls.SizeLabel, controls.Size, controls.SizeValue, false, false)
		setSliderState(controls.IconZoomLabel, controls.IconZoom, controls.IconZoomValue, false, false)
		setSliderState(controls.CooldownTextSizeLabel, controls.CooldownTextSize, controls.CooldownTextSizeValue, false, false)
		setSliderState(controls.ChargeTextSizeLabel, controls.ChargeTextSize, controls.ChargeTextSizeValue, false, false)
		setSliderState(controls.XLabel, controls.XOffset, controls.XValue, false, false)
		setSliderState(controls.YLabel, controls.YOffset, controls.YValue, false, false)
		setSliderState(controls.BarWidthLabel, controls.BarWidth, controls.BarWidthValue, false, false)
		setSliderState(controls.BarHeightLabel, controls.BarHeight, controls.BarHeightValue, false, false)
		setSliderState(controls.BarAlphaLabel, controls.BarAlpha, controls.BarAlphaValue, false, false)
		setFieldState(controls.BarStrataLabel, controls.BarStrata, false, false)
		setSliderState(controls.BarFrameLevelLabel, controls.BarFrameLevel, controls.BarFrameLevelValue, false, false)
		setSliderState(controls.InsetLabel, controls.Inset, controls.InsetValue, false, false)
		setSliderState(controls.BorderSizeLabel, controls.BorderSize, controls.BorderSizeValue, false, false)
		setFieldState(controls.BorderStrataLabel, controls.BorderStrata, false, false)
		setSliderState(controls.BorderFrameLevelLabel, controls.BorderFrameLevel, controls.BorderFrameLevelValue, false, false)
		setCheckState(controls.IndicatorBorder, false, false, false)
		setFieldState(controls.IndicatorBorderTextureLabel, controls.IndicatorBorderTexture, false, false)
		setSliderState(controls.IndicatorBorderSizeLabel, controls.IndicatorBorderSize, controls.IndicatorBorderSizeValue, false, false)
		setSliderState(controls.IndicatorBorderOffsetLabel, controls.IndicatorBorderOffset, controls.IndicatorBorderOffsetValue, false, false)
		setIndicatorBorderColorState(false, false)
		setColorState(false, false)
		setCheckState(controls.BarFillFrame, false, false, false)
		setCheckState(controls.BarDrainAnimation, false, false, false)
		setCheckState(controls.BarReverseFill, false, false, false)
		setCheckState(controls.CooldownSwipe, false, false, false)
		setCheckState(controls.CooldownEdge, false, false, false)
		setCheckState(controls.CooldownBling, false, false, false)
		setCheckState(controls.HideCooldownText, false, false, false)
		setCheckState(controls.HideChargeText, false, false, false)
		setColorPreview(controls.IndicatorBorderColorButton, { 0, 0, 0, 0.95 })
		setColorPreview(controls.ColorButton, { 1, 1, 1, 1 })
	end
	self._controlUpdateLock = nil

	if frame._layoutGroupControlRows then frame._layoutGroupControlRows() end
	if frame._updateGroupControlScroll then frame._updateGroupControlScroll() end
	if groupSelectionChanged then
		local viewport = frame.SettingsPanel and frame.SettingsPanel.GroupControlViewport
		if viewport and viewport.SetVerticalScroll then viewport:SetVerticalScroll(0) end
		local scroll = frame.SettingsPanel and frame.SettingsPanel.GroupControlScroll
		if scroll and scroll.Sync then scroll:Sync() end
	end
	self._lastGroupControlGroupId = selectedGroupId
end

local function clearPreview(unitFrame)
	if not unitFrame then return end
	for i = 1, #(unitFrame.SampleIcons or {}) do
		local icon = unitFrame.SampleIcons[i]
		if icon then
			icon:Hide()
			if icon.IndicatorBorder then icon.IndicatorBorder:Hide() end
			if icon.PreviewCooldown then
				if icon.PreviewCooldown.Clear then icon.PreviewCooldown:Clear() end
				icon.PreviewCooldown:Hide()
			end
			if icon.PreviewCount then
				icon.PreviewCount:SetText("")
				icon.PreviewCount:Hide()
			end
			icon._eqolPreviewAura = nil
			icon._eqolPreviewGroup = nil
			icon._eqolPreviewAC = nil
			icon._eqolPreviewSampleIndex = nil
		end
	end
	for i = 1, #(unitFrame.SampleTints or {}) do
		unitFrame.SampleTints[i]:Hide()
	end
	for i = 1, #(unitFrame.SampleBars or {}) do
		local bar = unitFrame.SampleBars[i]
		bar:Hide()
		bar._eqolPreviewGroup = nil
		bar._eqolPreviewSampleIndex = nil
		if bar.SetValue then bar:SetValue(1) end
	end
	for i = 1, #(unitFrame.SampleBorders or {}) do
		unitFrame.SampleBorders[i]:Hide()
	end
	if unitFrame.HealthTexture then unitFrame.HealthTexture:SetColorTexture(0.08, 0.42, 0.19, 1) end
end

local function ensurePreviewAuraWidgets(icon)
	if not icon then return end
	if icon.PreviewCooldown then return end
	local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	cooldown:SetAllPoints(icon)
	if cooldown.SetReverse then cooldown:SetReverse(true) end
	if cooldown.SetDrawEdge then cooldown:SetDrawEdge(true) end
	if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(true) end
	if cooldown.SetDrawBling then cooldown:SetDrawBling(true) end
	icon.PreviewCooldown = cooldown

	local overlay = CreateFrame("Frame", nil, icon)
	overlay:SetAllPoints(icon)
	if overlay.SetFrameStrata and cooldown.GetFrameStrata then overlay:SetFrameStrata(cooldown:GetFrameStrata()) end
	if overlay.SetFrameLevel and cooldown.GetFrameLevel then overlay:SetFrameLevel((cooldown:GetFrameLevel() or 0) + 5) end
	icon.PreviewOverlay = overlay

	local countText = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	countText:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -2, 2)
	icon.PreviewCount = countText
end

local function setPreviewFont(fontString, size, outline)
	if not fontString then return end
	local fontPath = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	local fallbackFont = STANDARD_TEXT_FONT or fontPath
	size = tonumber(size) or 12
	if size < 6 then size = 6 end
	if size > 64 then size = 64 end
	local styleChoice = outline or "OUTLINE"
	local resolvedFlags = styleChoice
	if addon.functions and addon.functions.ResolveFontStyle then
		local _, flags = addon.functions.ResolveFontStyle(styleChoice, "OUTLINE")
		resolvedFlags = flags
	elseif addon.functions and addon.functions.GetFontFlagsForStyle then
		resolvedFlags = addon.functions.GetFontFlagsForStyle(styleChoice, "OUTLINE")
		if resolvedFlags == nil and styleChoice == "__EQOL_GLOBAL_FONT_STYLE__" then resolvedFlags = "OUTLINE" end
	elseif styleChoice == "__EQOL_GLOBAL_FONT_STYLE__" then
		resolvedFlags = "OUTLINE"
	elseif styleChoice == "NONE" then
		resolvedFlags = nil
	end

	local ok = false
	if addon.functions and addon.functions.ApplyFontString then
		ok = addon.functions.ApplyFontString(fontString, fontPath, size, styleChoice, fallbackFont, "OUTLINE")
	else
		ok = fontString:SetFont(fontPath, size, resolvedFlags)
		if ok == false then ok = fontString:SetFont(fallbackFont, size, resolvedFlags) end
	end
	if ok == false then fontString:SetFont(fallbackFont, size, resolvedFlags) end
	if addon.functions and addon.functions.ApplyFontStyleShadow then addon.functions.ApplyFontStyleShadow(fontString, styleChoice, "OUTLINE") end
end

local function applyPreviewIconZoom(icon, iconZoom)
	local texture = icon and icon.Texture
	if not (texture and texture.SetTexCoord) then return end
	if addon.IconShape and addon.IconShape.NormalizeIconZoom then
		iconZoom = addon.IconShape.NormalizeIconZoom(iconZoom)
	else
		iconZoom = roundInt(tonumber(iconZoom) or 0)
		if iconZoom < 0 then iconZoom = 0 end
		if iconZoom > 35 then iconZoom = 35 end
	end
	if iconZoom <= 0 then
		texture:SetTexCoord(0, 1, 0, 1)
		return
	end
	if addon.IconShape and addon.IconShape.ApplyTextureZoom then
		addon.IconShape.ApplyTextureZoom(texture, iconZoom, "_hbPreviewIconTexCoord", 0)
	else
		texture:SetTexCoord(0, 1, 0, 1)
	end
end

local function getPreviewCooldownTiming(sampleIndex, now, loopEnabled, loopOrigin)
	sampleIndex = tonumber(sampleIndex) or 1
	now = tonumber(now) or ((GetTime and GetTime()) or 0)
	local duration = 8 + ((sampleIndex - 1) % 3) * 4
	if loopEnabled == true then
		local origin = tonumber(loopOrigin) or now
		local phaseOffset = ((sampleIndex - 1) % 4) * 0.55
		local elapsed = (now - origin + phaseOffset) % duration
		local remaining = duration - elapsed
		if remaining <= 0 then remaining = duration end
		return duration, remaining
	end
	local remaining = duration * (0.25 + ((sampleIndex - 1) % 3) * 0.2)
	return duration, remaining
end

local function getPreviewTimedFill(sampleIndex, now, loopEnabled, loopOrigin)
	local duration, remaining = getPreviewCooldownTiming(sampleIndex, now, loopEnabled, loopOrigin)
	duration = tonumber(duration)
	remaining = tonumber(remaining)
	if not (duration and duration > 0 and remaining) then return 1 end
	local fill = remaining / duration
	if fill < 0 then fill = 0 end
	if fill > 1 then fill = 1 end
	return fill
end

local function applyPreviewCooldown(icon, group, ac, sampleIndex, now, loopEnabled, loopOrigin)
	if not icon then return end
	ensurePreviewAuraWidgets(icon)
	local cooldown = icon.PreviewCooldown
	if not cooldown then return end

	local drawSwipe = group.showCooldownSwipe ~= false
	local drawEdge = group.showCooldownEdge ~= false
	local drawBling = group.showCooldownBling ~= false
	if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(drawSwipe) end
	if cooldown.SetDrawEdge then cooldown:SetDrawEdge(drawEdge) end
	if cooldown.SetDrawBling then cooldown:SetDrawBling(drawBling) end
	if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(group.hideCooldownText == true) end

	now = tonumber(now) or ((GetTime and GetTime()) or 0)
	local duration, remaining = getPreviewCooldownTiming(sampleIndex, now, loopEnabled, loopOrigin)
	local startTime = now - (duration - remaining)
	cooldown:SetCooldown(startTime, duration)
	cooldown:Show()

	local cooldownText = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
	if cooldownText then
		cooldownText:ClearAllPoints()
		cooldownText:SetPoint("CENTER", icon, "CENTER", 0, 0)
		local size = group.cooldownTextSize
		if size == nil and ac then size = ac.cooldownFontSize end
		setPreviewFont(cooldownText, size or 12, ac and ac.cooldownFontOutline)
	end
end

local function applyPreviewBarFill(bar, group, sampleIndex, now, loopEnabled, loopOrigin)
	if not (bar and bar.SetValue) then return end
	if not (group and group.barDrainAnimation == true) then
		bar:SetValue(1)
		return
	end
	bar:SetValue(getPreviewTimedFill(sampleIndex, now, loopEnabled, loopOrigin))
end

local function applyPreviewCharges(icon, group, ac, sampleIndex)
	if not icon then return end
	ensurePreviewAuraWidgets(icon)
	local text = icon.PreviewCount
	if not text then return end

	if group.hideChargeText == true then
		text:SetText("")
		text:Hide()
		return
	end

	local sampleCounts = { 4, 2, 5, 3 }
	local count = sampleCounts[((sampleIndex - 1) % #sampleCounts) + 1]
	if not count or count <= 1 then
		text:SetText("")
		text:Hide()
		return
	end
	local size = group.chargeTextSize
	if size == nil and ac then size = ac.countFontSize end
	setPreviewFont(text, size or 14, ac and ac.countFontOutline)
	text:SetText(tostring(count))
	text:Show()
end

function Editor:SetPreviewLoopEnabled(enabled)
	enabled = enabled == true
	if self._previewLoopEnabled == enabled then
		self:UpdatePreviewLoopTicker()
		return
	end
	self._previewLoopEnabled = enabled
	if enabled then
		self._previewLoopStart = (GetTime and GetTime()) or 0
	else
		self._previewLoopStart = nil
	end
	local frame = self.frame
	if frame and frame.Controls and frame.Controls.PreviewLoop and frame.Controls.PreviewLoop.GetChecked and frame.Controls.PreviewLoop:GetChecked() ~= enabled then
		frame.Controls.PreviewLoop:SetChecked(enabled)
	end
	self:RefreshPreview()
end

function Editor:SetPreviewAllEnabled(enabled)
	enabled = enabled == true
	if (self._previewAllEnabled ~= false) == enabled then return end
	self._previewAllEnabled = enabled
	local frame = self.frame
	if frame and frame.Controls and frame.Controls.PreviewAll and frame.Controls.PreviewAll.GetChecked and frame.Controls.PreviewAll:GetChecked() ~= enabled then
		frame.Controls.PreviewAll:SetChecked(enabled)
	end
	self:RefreshPreview()
end

function Editor:TickPreviewLoop()
	if self._previewLoopEnabled ~= true then return end
	local frame = self.frame
	local preview = frame and frame.PreviewPanel and frame.PreviewPanel.Frame and frame.PreviewPanel.Frame.UnitFrame
	if not preview then return end
	local now = (GetTime and GetTime()) or 0
	local loopOrigin = self._previewLoopStart or now
	for i = 1, #(preview.SampleIcons or EMPTY) do
		local icon = preview.SampleIcons[i]
		if icon and icon:IsShown() and icon._eqolPreviewAura == true then
			local group = icon._eqolPreviewGroup
			if group then applyPreviewCooldown(icon, group, icon._eqolPreviewAC or EMPTY, icon._eqolPreviewSampleIndex or 1, now, true, loopOrigin) end
		end
	end
	for i = 1, #(preview.SampleBars or EMPTY) do
		local bar = preview.SampleBars[i]
		if bar and bar:IsShown() and bar._eqolPreviewGroup then applyPreviewBarFill(bar, bar._eqolPreviewGroup, bar._eqolPreviewSampleIndex or 1, now, true, loopOrigin) end
	end
end

function Editor:UpdatePreviewLoopTicker()
	local frame = self.frame
	local shouldRun = self._previewLoopEnabled == true and frame and frame:IsShown() and C_Timer and C_Timer.NewTicker
	if not shouldRun then
		if self._previewLoopTicker and self._previewLoopTicker.Cancel then self._previewLoopTicker:Cancel() end
		self._previewLoopTicker = nil
		return
	end
	if self._previewLoopTicker then return end
	if not self._previewLoopStart then self._previewLoopStart = (GetTime and GetTime()) or 0 end
	self._previewLoopTicker = C_Timer.NewTicker(0.1, function()
		if not (Editor and Editor._previewLoopEnabled == true and Editor.frame and Editor.frame:IsShown()) then
			if Editor and Editor._previewLoopTicker and Editor._previewLoopTicker.Cancel then Editor._previewLoopTicker:Cancel() end
			if Editor then Editor._previewLoopTicker = nil end
			return
		end
		Editor:TickPreviewLoop()
	end)
end

local function resolveColor(color)
	if type(color) == "table" then return color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1 end
	return 1, 1, 1, 1
end

local function resolveBorderTexture(key)
	if UFHelper and UFHelper.resolveBorderTexture then return UFHelper.resolveBorderTexture(key) end
	if not key or key == "" or key == "DEFAULT" then return "Interface\\Buttons\\WHITE8x8" end
	return key
end

local function ensurePreviewIndicatorBorder(icon)
	if not icon then return nil end
	local border = icon.IndicatorBorder
	if not border then
		border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
		border:EnableMouse(false)
		icon.IndicatorBorder = border
	end
	border:SetParent(icon)
	if border.SetFrameStrata and icon.GetFrameStrata then border:SetFrameStrata(icon:GetFrameStrata()) end
	if border.SetFrameLevel and icon.GetFrameLevel then border:SetFrameLevel((icon:GetFrameLevel() or 0) + 5) end
	return border
end

local function ensurePreviewExpirationPulseBorder(icon)
	if not icon then return nil end
	local border = icon.ExpirationPulseBorder
	if not border then
		border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
		border:EnableMouse(false)
		icon.ExpirationPulseBorder = border
	end
	border:SetParent(icon)
	if border.SetFrameStrata and icon.GetFrameStrata then border:SetFrameStrata(icon:GetFrameStrata()) end
	if border.SetFrameLevel and icon.GetFrameLevel then border:SetFrameLevel((icon:GetFrameLevel() or 0) + 8) end
	return border
end

local function hidePreviewExpirationPulseBorder(icon)
	local border = icon and icon.ExpirationPulseBorder
	if border then border:Hide() end
end

local function applyPreviewIndicatorBorder(icon, group)
	if not icon then return end
	local style = tostring(group and group.style or ""):upper()
	local enabled = (style == "ICON" or style == "SQUARE") and group and group.indicatorBorderEnabled == true
	local border = icon.IndicatorBorder
	if not enabled then
		if border then border:Hide() end
		return
	end
	border = ensurePreviewIndicatorBorder(icon)
	if not border then return end
	local size = roundInt(tonumber(group.indicatorBorderSize) or 1)
	if size < 1 then size = 1 end
	if size > 24 then size = 24 end
	local offset = roundInt(tonumber(group.indicatorBorderOffset) or 0)
	if offset < -12 then offset = -12 end
	if offset > 12 then offset = 12 end
	local texture = resolveBorderTexture(group.indicatorBorderTexture or "DEFAULT")
	local key = tostring(texture) .. "|" .. tostring(size)
	if border._eqolBackdropKey ~= key then
		border._eqolBackdropKey = key
		border:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = texture,
			tile = false,
			edgeSize = size,
			insets = { left = size, right = size, top = size, bottom = size },
		})
	end
	if border._eqolOffset ~= offset then
		border._eqolOffset = offset
		border:ClearAllPoints()
		border:SetPoint("TOPLEFT", icon, "TOPLEFT", -offset, offset)
		border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", offset, -offset)
	end
	local br, bg, bb, ba = resolveColor(group.indicatorBorderColor)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(br, bg, bb, ba)
	border:Show()
end

local function applyPreviewExpirationPulse(icon, group, rule, sampleIndex, now, loopEnabled, loopOrigin)
	if not (icon and group and rule and rule.expirationPulseEnabled == true) then
		hidePreviewExpirationPulseBorder(icon)
		return
	end
	local style = tostring(group.style or ""):upper()
	if style ~= "ICON" and style ~= "SQUARE" then
		hidePreviewExpirationPulseBorder(icon)
		return
	end
	local threshold = roundInt(tonumber(rule.expirationPulseThreshold) or 3)
	if threshold < 1 then threshold = 1 end
	if threshold > 10 then threshold = 10 end
	local _, remaining = getPreviewCooldownTiming(sampleIndex, now, loopEnabled, loopOrigin)
	local inPulse = remaining and remaining <= threshold
	if icon.PreviewCooldown and icon.PreviewCooldown.SetHideCountdownNumbers then
		icon.PreviewCooldown:SetHideCountdownNumbers((group.hideCooldownText == true) or (rule.expirationPulseCountdownOnly == true and not inPulse))
	end
	if not inPulse then
		hidePreviewExpirationPulseBorder(icon)
		return
	end
	local useIndicatorBorder = group.indicatorBorderEnabled == true
	local border = useIndicatorBorder and ensurePreviewIndicatorBorder(icon) or ensurePreviewExpirationPulseBorder(icon)
	if not border then return end
	if useIndicatorBorder then hidePreviewExpirationPulseBorder(icon) end
	local pulse = (math.sin(((threshold - remaining) * 2) * math.pi) + 1) * 0.5
	local size = roundInt(tonumber(group.indicatorBorderSize) or 2)
	if useIndicatorBorder then
		if size < 1 then size = 1 end
	else
		if size < 2 then size = 2 end
	end
	if size > 24 then size = 24 end
	local offset = roundInt(tonumber(group.indicatorBorderOffset) or 0)
	if offset < -12 then offset = -12 end
	if offset > 12 then offset = 12 end
	local texture = resolveBorderTexture(group.indicatorBorderTexture or "DEFAULT")
	local key = tostring(texture) .. "|" .. tostring(size)
	if border._eqolBackdropKey ~= key then
		border._eqolBackdropKey = key
		border:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = texture,
			tile = false,
			edgeSize = size,
			insets = { left = size, right = size, top = size, bottom = size },
		})
	end
	if border._eqolOffset ~= offset then
		border._eqolOffset = offset
		border:ClearAllPoints()
		border:SetPoint("TOPLEFT", icon, "TOPLEFT", -offset, offset)
		border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", offset, -offset)
	end
	local br, bg, bb, ba = resolveColor(rule.expirationPulseColor or { 1, 0.2, 0.2, 1 })
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(br, bg, bb, max(ba or 1, 0.85) * (0.08 + (0.92 * pulse)))
	border:Show()
end

local function applyPreviewHealthTint(unitFrame, tintR, tintG, tintB, tintA)
	if not (unitFrame and unitFrame.HealthTexture) then return end
	local baseR, baseG, baseB, baseA = 0.08, 0.42, 0.19, 1
	if tintA == nil then
		unitFrame.HealthTexture:SetColorTexture(baseR, baseG, baseB, baseA)
		return
	end
	local strength = max(0, min(1, tonumber(tintA) or 0))
	if strength <= 0 then
		unitFrame.HealthTexture:SetColorTexture(baseR, baseG, baseB, baseA)
		return
	end
	local inv = 1 - strength
	unitFrame.HealthTexture:SetColorTexture((baseR * inv) + ((tintR or baseR) * strength), (baseG * inv) + ((tintG or baseG) * strength), (baseB * inv) + ((tintB or baseB) * strength), baseA)
end

local function ruleAppliesToPreviewKind(rule, kind)
	if not rule then return false end
	kind = tostring(kind or "party"):lower()
	if kind == "mt" or kind == "ma" then kind = "raid" end
	if kind == "raid" then return rule.appliesRaid ~= false end
	return rule.appliesParty ~= false
end

local function getRuleIdsForGroup(placement, groupId, kind, classToken)
	local list = {}
	eachGroupRule(placement, groupId, function(ruleId, rule)
		if rule and rule.enabled ~= false and ruleAppliesToPreviewKind(rule, kind) then
			if classToken == nil or isRuleForClass(rule, classToken) then list[#list + 1] = ruleId end
		end
	end)
	return list
end

local function isPreviewRuleActive(rule)
	if not rule or rule.enabled == false then return false end
	local active = true
	if rule["not"] then active = not active end
	return active
end

local function isPreviewGroupTintActive(placement, group, kind, classToken)
	if not (placement and group and group.id) then return false end
	local ruleIds = getRuleIdsForGroup(placement, group.id, kind, classToken)
	local ruleMatch = tostring(group.ruleMatch or "ANY"):upper()
	if ruleMatch == "ALL" then
		if #ruleIds == 0 then return false end
		for i = 1, #ruleIds do
			local rule = placement.rulesById and placement.rulesById[ruleIds[i]]
			if not isPreviewRuleActive(rule) then return false end
		end
		return true
	end
	for i = 1, #ruleIds do
		local rule = placement.rulesById and placement.rulesById[ruleIds[i]]
		if isPreviewRuleActive(rule) then return true end
	end
	return false
end

local function getPreviewPriorityRuleForGroup(placement, groupId, kind, classToken)
	local ruleIds = getRuleIdsForGroup(placement, groupId, kind, classToken)
	for i = 1, #ruleIds do
		local rule = placement.rulesById and placement.rulesById[ruleIds[i]]
		if isPreviewRuleActive(rule) then return rule, ruleIds[i] end
	end
	return nil, nil
end

function Editor:RefreshPreview()
	local frame = self:EnsureFrame()
	local cfg, placement = self:GetContext()
	local ac = cfg and cfg.auras and cfg.auras.buff or EMPTY
	local loopEnabled = self._previewLoopEnabled == true
	local now = (GetTime and GetTime()) or 0
	if loopEnabled and not self._previewLoopStart then self._previewLoopStart = now end
	local loopOrigin = self._previewLoopStart or now
	local previewAll = self._previewAllEnabled ~= false
	if frame.Controls and frame.Controls.PreviewLoop then frame.Controls.PreviewLoop:SetChecked(loopEnabled) end
	if frame.Controls and frame.Controls.PreviewAll then frame.Controls.PreviewAll:SetChecked(previewAll) end
	local preview = frame.PreviewPanel and frame.PreviewPanel.Frame and frame.PreviewPanel.Frame.UnitFrame
	if not preview then
		self:UpdatePreviewLoopTicker()
		return
	end
	clearPreview(preview)

	if not placement then
		self:UpdatePreviewLoopTicker()
		return
	end
	local order = placement.groupOrder or EMPTY
	local iconIndex, barIndex, borderIndex = 1, 1, 1
	local tintR, tintG, tintB, tintA
	local hasTint = false
	local w, h = preview:GetWidth(), preview:GetHeight()
	for index = 1, #order do
		local groupId = order[index]
		local group = placement.groupsById and placement.groupsById[groupId]
		if group and (previewAll or groupId == self.selectedGroupId) then
			local style = tostring(group.style or "ICON"):upper()
			local iconMode = tostring(group.iconMode or "ALL"):upper()
			local anchorPoint = group.anchorPoint or "CENTER"
			local selected = groupId == self.selectedGroupId
			local anchor = ANCHOR_COORDS[anchorPoint] or ANCHOR_COORDS.CENTER
			local anchorX = (anchor[1] or 0) * w
			local anchorY = (anchor[2] or 0) * h
			local x = group.x or 0
			local y = group.y or 0
			x, y = clampGroupOffsetsForFrame(group, w, h)
			group.x, group.y = x, y
			local baseX = anchorX + x
			local baseY = anchorY + y

			if style == "ICON" or style == "SQUARE" then
				local ruleIds = getRuleIdsForGroup(placement, group.id, self.kind)
				local isPriorityMode = iconMode == "PRIORITY"
				if isPriorityMode and #ruleIds > 1 then
					for trim = #ruleIds, 2, -1 do
						ruleIds[trim] = nil
					end
				end
				local size = max(4, tonumber(group.size) or 16)
				local spacing = max(0, tonumber(group.spacing) or 0)
				local perRow = max(1, tonumber(group.perRow) or 1)
				local maxIcons = max(0, tonumber(group.max) or 3)
				local previewCount = isPriorityMode and min(maxIcons, 1) or min(maxIcons, 3)
				local shown
				if isPriorityMode then
					shown = maxIcons > 0 and 1 or 0
				else
					shown = min(maxIcons, max(#ruleIds, previewCount))
				end
				local primary, secondary = HB.GetGrowthAxes(group.growth)
				local primaryHorizontal = primary == "LEFT" or primary == "RIGHT"
				for i = 1, shown do
					local row, col
					if primaryHorizontal then
						row = floor((i - 1) / perRow)
						col = (i - 1) % perRow
					else
						row = (i - 1) % perRow
						col = floor((i - 1) / perRow)
					end
					local horizontalDir = primaryHorizontal and primary or secondary
					local verticalDir = primaryHorizontal and secondary or primary
					local xSign = horizontalDir == "RIGHT" and 1 or -1
					local ySign = verticalDir == "UP" and 1 or -1
					local px = x + (col * (size + spacing) * xSign)
					local py = y + (row * (size + spacing) * ySign)
					local icon = preview.SampleIcons[iconIndex]
					iconIndex = iconIndex + 1
					if icon then
						icon:SetSize(size, size)
						icon:ClearAllPoints()
						icon:SetPoint(anchorPoint, preview, anchorPoint, px, py)
						local ruleId = ruleIds[i]
						if ruleId == nil and #ruleIds > 0 then
							local cycleIndex = ((i - 1) % #ruleIds) + 1
							ruleId = ruleIds[cycleIndex]
						end
						local rule = ruleId and placement.rulesById and placement.rulesById[ruleId]
						local family = rule and HB.GetFamilyById and HB.GetFamilyById(rule.spellFamilyId)
						local iconTex = family and family._resolvedIcon or nil
						if not iconTex and family and family.spellIds and family.spellIds[1] then
							if C_Spell and C_Spell.GetSpellTexture then
								iconTex = C_Spell.GetSpellTexture(family.spellIds[1])
							elseif GetSpellTexture then
								iconTex = GetSpellTexture(family.spellIds[1])
							end
						end
						if style == "SQUARE" then
							local squareColor = (rule and rule.color) or group.color
							local r, g, b, a = resolveColor(squareColor)
							icon.Texture:SetTexture("Interface\\Buttons\\WHITE8x8")
							applyPreviewIconZoom(icon, 0)
							icon.Texture:SetVertexColor(r, g, b, a)
							if icon.Texture.SetDesaturated then icon.Texture:SetDesaturated(false) end
						else
							icon.Texture:SetTexture(iconTex or 134400)
							applyPreviewIconZoom(icon, group.iconZoom)
							icon.Texture:SetVertexColor(1, 1, 1, 1)
							if icon.Texture.SetDesaturated then icon.Texture:SetDesaturated(HB.ShouldDesaturateRuleIcon and HB.ShouldDesaturateRuleIcon(group, rule) or false) end
						end
						icon._eqolPreviewAura = true
						icon._eqolPreviewGroup = group
						icon._eqolPreviewAC = ac
						icon._eqolPreviewSampleIndex = i
						applyPreviewCooldown(icon, group, ac, i, now, loopEnabled, loopOrigin)
						applyPreviewCharges(icon, group, ac, i)
						icon:SetBackdropBorderColor(0, 0, 0, 0)
						applyPreviewIndicatorBorder(icon, group)
						applyPreviewExpirationPulse(icon, group, rule, i, now, loopEnabled, loopOrigin)
						icon:Show()
					end
				end
			elseif style == "BAR" then
				local bar = preview.SampleBars[barIndex]
				barIndex = barIndex + 1
				if bar then
					local colorRule = getPreviewPriorityRuleForGroup(placement, group.id, self.kind)
					local r, g, b, a = resolveColor((colorRule and colorRule.color) or group.color)
					if group.barAlpha ~= nil then a = max(0, min(1, tonumber(group.barAlpha) or a)) end
					if not selected then a = min(a, 0.45) end
					bar:SetStatusBarColor(r, g, b, a)
					bar:SetMinMaxValues(0, 1)
					bar:SetOrientation(tostring(group.barOrientation or "HORIZONTAL"):upper())
					if UFHelper and UFHelper.applyStatusBarReverseFill then UFHelper.applyStatusBarReverseFill(bar, group.barDrainAnimation == true and group.barReverseFill == true) end
					bar:ClearAllPoints()
					local inset = max(0, tonumber(group.inset) or 0)
					local barWidth, barHeight, useSizedPlacement = 0, 0, false
					if HB.GetBarDisplaySize then barWidth, barHeight, useSizedPlacement = HB.GetBarDisplaySize(group, w, h) end
					if useSizedPlacement then
						bar:SetSize(barWidth, barHeight)
						bar:SetPoint(anchorPoint, preview, anchorPoint, x, y)
					elseif tostring(group.barOrientation or "HORIZONTAL") == "VERTICAL" then
						local thickness = max(1, tonumber(group.barThickness) or 6)
						bar:SetPoint("TOP", preview, "TOP", baseX, baseY - inset)
						bar:SetPoint("BOTTOM", preview, "BOTTOM", baseX, baseY + inset)
						bar:SetWidth(thickness)
					else
						local thickness = max(1, tonumber(group.barThickness) or 6)
						bar:SetPoint("LEFT", preview, "LEFT", baseX + inset, baseY)
						bar:SetPoint("RIGHT", preview, "RIGHT", baseX - inset, baseY)
						bar:SetHeight(thickness)
					end
					bar._eqolPreviewGroup = group
					bar._eqolPreviewSampleIndex = 1
					applyPreviewBarFill(bar, group, 1, now, loopEnabled, loopOrigin)
					bar:Show()
				end
			elseif style == "BORDER" then
				local border = preview.SampleBorders[borderIndex]
				borderIndex = borderIndex + 1
				if border then
					local colorRule = getPreviewPriorityRuleForGroup(placement, group.id, self.kind)
					local r, g, b, a = resolveColor((colorRule and colorRule.color) or group.color)
					if not selected then a = min(a, 0.6) end
					local inset = max(0, tonumber(group.inset) or 0)
					local size = max(1, tonumber(group.borderSize) or 1)
					border:ClearAllPoints()
					border:SetPoint("TOPLEFT", preview, "TOPLEFT", baseX + inset, baseY - inset)
					border:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", baseX - inset, baseY + inset)
					border:SetBackdrop({
						bgFile = "Interface\\Buttons\\WHITE8x8",
						edgeFile = "Interface\\Buttons\\WHITE8x8",
						tile = false,
						edgeSize = size,
						insets = { left = 0, right = 0, top = 0, bottom = 0 },
					})
					border:SetBackdropColor(0, 0, 0, 0)
					border:SetBackdropBorderColor(r, g, b, a)
					border:Show()
				end
			elseif style == "TINT" then
				local active = isPreviewGroupTintActive(placement, group, self.kind)
				if active or selected then
					local colorRule = active and getPreviewPriorityRuleForGroup(placement, group.id, self.kind) or nil
					local r, g, b, a = resolveColor((colorRule and colorRule.color) or group.color)
					if not active and selected then a = min(a, 0.35) end
					if selected then
						tintR, tintG, tintB, tintA = r, g, b, a
						hasTint = true
					elseif not hasTint then
						tintR, tintG, tintB, tintA = r, g, b, a
						hasTint = true
					end
				end
			end
		end
	end

	applyPreviewHealthTint(preview, tintR, tintG, tintB, hasTint and tintA or nil)
	self:UpdatePreviewLoopTicker()
end

function Editor:RefreshControls()
	local frame = self:EnsureFrame()
	local _, placement = self:GetContext()
	if frame.KindValue then frame.KindValue:SetText(tr("UFGroupHealerBuffEditorScopeShared", "Shared (Party + Raid)")) end
	if frame.EnabledCheck and placement then frame.EnabledCheck:SetChecked(placement.enabled == true) end
	self:RefreshGroupControls()
	self:RefreshRuleControls()
end

function Editor:RefreshAll()
	self:EnsureSelection()
	self:RefreshLists()
	self:RefreshControls()
	self:RefreshPreview()
end

function Editor:Show(kind)
	kind = tostring(kind or "party"):lower()
	if kind ~= "party" and kind ~= "raid" then kind = "party" end
	self.kind = kind
	self:EnsureFrame()
	self.groupOffset = 0
	self.ruleOffset = 0
	self:EnsureSelection()
	self:RefreshAll()
	self.frame:Show()
	self.frame:Raise()
end

function Editor:Hide()
	if self.frame then self.frame:Hide() end
end

function Editor:Toggle(kind)
	self:EnsureFrame()
	if self.frame:IsShown() then
		self:Hide()
		return
	end
	self:Show(kind)
end

function Editor:IsShown() return self.frame and self.frame:IsShown() == true end

local function isSlashCommandRegistered(command)
	if addon.functions and addon.functions.IsSlashCommandRegistered then return addon.functions.IsSlashCommandRegistered(command) end
	if not command then return false end
	command = command:lower()
	for key, value in pairs(_G) do
		if type(key) == "string" and key:match("^SLASH_") and type(value) == "string" then
			if value:lower() == command then return true end
		end
	end
	return false
end

local function setSlashCommandAlias(slot, command)
	if addon.functions and addon.functions.SetSlashCommandAlias then return addon.functions.SetSlashCommandAlias("EQOLHBP", slot, command) end
	command = type(command) == "string" and command:lower() or nil
	_G["SLASH_EQOLHBP" .. slot] = command
	return command
end

local function registerHealerBuffPlacementSlashCommand()
	if not SlashCmdList then return end
	local command = "/hbp"
	if isSlashCommandRegistered(command) then
		local key = _G["SLASH_EQOLHBP1"]
		local owned = SlashCmdList["EQOLHBP"] and type(key) == "string" and key:lower() == command
		if not owned then return end
	end
	setSlashCommandAlias(1, command)
	SlashCmdList["EQOLHBP"] = function(msg)
		if InCombatLockdown and InCombatLockdown() then return end
		local arg = tostring(msg or ""):lower():match("%S+") or ""
		local kind = "raid"
		if arg == "party" or arg == "p" then kind = "party" end
		Editor:Toggle(kind)
	end
end

registerHealerBuffPlacementSlashCommand()
