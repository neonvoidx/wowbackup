local addon = _G.EnhanceQoL
local L = addon.L
local UI = {}
addon.Bags.SettingsNavigation = UI

UI.checkboxes = { "OneBagMode", "OneBagFreeSlotsAtEnd", "ShowCategories", "CombineFreeSlots", "ShowFreeSlots", "CombineDuplicateItems", "ClearNewItemsOnHeaderClick", "CompactCategoryLayout", "CategoryTreeView", "ShowCloseButton", "RememberLastBankTab", "UseIntegratedBank" }
UI.appearance = { { "SkinPresetLabel", "SkinPresetButton" }, { "IconShapeLabel", "IconShapeButton" }, { "FreeSlotDisplayLabel", "FreeSlotDisplayButton" }, { "FreeSlotNormalColorLabel", "FreeSlotNormalColorSwatch" }, { "FreeSlotReagentColorLabel", "FreeSlotReagentColorSwatch" }, { "FrameBackgroundLabel", "FrameBackgroundButton" }, { "FrameBackgroundColorLabel", "FrameBackgroundColorSwatch" }, { "FrameBackgroundOpacityLabel", "FrameBackgroundOpacityStepper" }, { "FrameBorderTextureLabel", "FrameBorderTextureButton" }, { "FrameBorderColorLabel", "FrameBorderColorSwatch" }, { "FrameBorderSizeLabel", "FrameBorderSizeStepper" }, { "FrameBorderOffsetLabel", "FrameBorderOffsetStepper" } }
UI.typography = { { "TextFontLabel", "TextFontButton" }, { "TextSizeLabel", "TextSizeStepper" }, { "TextOverlaySizeLabel", "TextOverlaySizeStepper" }, { "TextOutlineLabel", "TextOutlineButton" } }

function UI.FlatButton(button)
	if button._bagsFlat then return end
	button._bagsFlat = true
	for _, state in ipairs({ { "Normal", 0.12, 0.17, 0.23, 1 }, { "Highlight", 0.3, 0.65, 1, 0.22 }, { "Pushed", 0.16, 0.38, 0.56, 1 }, { "Disabled", 0.08, 0.10, 0.13, 1 } }) do
		local setter, getter = button["Set" .. state[1] .. "Texture"], button["Get" .. state[1] .. "Texture"]
		setter(button, "Interface\\Buttons\\WHITE8x8")
		local texture = addon.PixelUtil.ApplyTexturePixelSnapping(getter(button))
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetVertexColor(state[2], state[3], state[4], state[5])
	end
	button:SetNormalFontObject(GameFontHighlightSmall)
	button:SetHighlightFontObject(GameFontHighlightSmall)
	button:SetDisabledFontObject(GameFontDisableSmall)
end

-- Plain buttons avoid template scripts restoring the native artwork on state changes.
function UI.CreateButton(_, name, parent)
	local button = CreateFrame("Button", name, parent)
	local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", 6, 0)
	label:SetPoint("RIGHT", -6, 0)
	label:SetWordWrap(false)
	button:SetFontString(label)
	UI.FlatButton(button)
	return button
end

function UI.CreateCheckbox(_, name, parent)
	local button = CreateFrame("CheckButton", name, parent)
	button:SetSize(24, 24)
	local background = addon.PixelUtil.ApplyTexturePixelSnapping(button:CreateTexture(nil, "BACKGROUND"))
	background:SetSize(17, 17)
	background:SetPoint("CENTER")
	background:SetColorTexture(0.07, 0.1, 0.14, 1)
	button.BagsCheckboxBorder = {}
	for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
		local edge = addon.PixelUtil.ApplyTexturePixelSnapping(button:CreateTexture(nil, "BORDER"))
		edge:SetPoint(side, background, side)
		edge:SetSize((side == "TOP" or side == "BOTTOM") and 17 or 1, (side == "TOP" or side == "BOTTOM") and 1 or 17)
		edge:SetColorTexture(0.48, 0.6, 0.72, 1)
		button.BagsCheckboxBorder[#button.BagsCheckboxBorder + 1] = edge
	end
	local check = addon.PixelUtil.ApplyTexturePixelSnapping(button:CreateTexture(nil, "OVERLAY"))
	check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:SetSize(22, 22)
	check:SetPoint("CENTER")
	check:SetVertexColor(0.45, 0.85, 1, 1)
	button:SetCheckedTexture(check)
	local disabled = addon.PixelUtil.ApplyTexturePixelSnapping(button:CreateTexture(nil, "OVERLAY"))
	disabled:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	disabled:SetSize(22, 22)
	disabled:SetPoint("CENTER")
	disabled:SetVertexColor(0.42, 0.5, 0.6, 1)
	button:SetDisabledCheckedTexture(disabled)
	local hover = addon.PixelUtil.ApplyTexturePixelSnapping(button:CreateTexture(nil, "HIGHLIGHT"))
	hover:SetColorTexture(0.3, 0.65, 1, 0.25)
	hover:SetSize(17, 17)
	hover:SetPoint("CENTER")
	button:SetHighlightTexture(hover)
	return button
end

-- Nested lists pass wheel input outward when they cannot scroll any further.
function UI.ScrollMouseWheel(frame, delta)
	while frame do
		local bar = frame.ScrollBar
		if bar then
			local low, high = bar:GetMinMaxValues()
			local current = bar:GetValue()
			local value = math.max(low, math.min(high, current - delta * 32))
			if value ~= current then
				bar:SetValue(value)
				return
			end
		end
		frame = frame:GetParent()
	end
end

-- Keep the bar outside the clipped viewport while retaining its visibility lifecycle.
function UI.StyleScrollBar(scrollFrame, scrollBar)
	scrollBar:SetParent(scrollFrame:GetParent())
	-- The template callback resolves the scroll target through GetParent().
	-- Bind the original viewport explicitly after moving the bar out of its clip.
	scrollBar:SetScript("OnValueChanged", function(_, value) scrollFrame:SetVerticalScroll(value) end)
	scrollBar:SetFrameLevel(scrollFrame:GetFrameLevel() + 2)
	scrollFrame:HookScript("OnHide", function() scrollBar:Hide() end)
	scrollFrame:HookScript("OnShow", function()
		local _, maximum = scrollBar:GetMinMaxValues()
		scrollBar:SetShown(maximum > 0)
	end)
	local track = addon.PixelUtil.ApplyTexturePixelSnapping(scrollBar:CreateTexture(nil, "BACKGROUND"))
	track:SetAllPoints()
	track:SetColorTexture(0.12, 0.17, 0.23, 1)
	scrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
	local thumb = addon.PixelUtil.ApplyTexturePixelSnapping(scrollBar:GetThumbTexture())
	thumb:SetSize(12, 32)
	thumb:SetVertexColor(0.4, 0.75, 1, 1)
end

function UI.StyleNavigationButton(button)
	button:SetSize(154, 42)
	UI.FlatButton(button)
	button.Background:Hide()
	button.HighlightTexture:Hide()
	button.SelectedTexture:SetTexture("Interface\\Buttons\\WHITE8x8")
	button.SelectedTexture:ClearAllPoints()
	button.SelectedTexture:SetPoint("TOPLEFT")
	button.SelectedTexture:SetPoint("BOTTOMLEFT")
	button.SelectedTexture:SetWidth(3)
	button.SelectedTexture:SetVertexColor(0.3, 0.7, 1, 1)
	button.Icon:ClearAllPoints()
	button.Icon:SetPoint("LEFT", 12, 0)
	button.Icon:SetSize(20, 20)
	local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", button, "LEFT", 40, 0)
	label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
	label:SetJustifyH("LEFT")
	label:SetText(button.tooltipTitle)
	button.NavLabel = label
	-- Keep icons fixed when pressing a text navigation row.
	button:SetScript("OnMouseDown", nil)
	button:SetScript("OnMouseUp", nil)
end

function UI.StyleFrame(frame)
	frame.Background:SetTexture("Interface\\Buttons\\WHITE8x8")
	frame.Background:SetVertexColor(0.025, 0.035, 0.055, 1)
	frame.Background:SetAlpha(1)
	frame.PanelBackground:SetColorTexture(0.025, 0.035, 0.055, 1)
	frame.PanelShade:SetColorTexture(0, 0, 0, 0)
	frame.PanelBorder:Hide()
	frame.PanelTopDetail:Hide()
	frame.TitleText:SetTextColor(0.85, 0.92, 1)
	frame.NavPanel:ClearAllPoints()
	frame.NavPanel:SetPoint("TOPLEFT", frame.PanelBackground, "TOPLEFT", 12, -34)
	frame.NavPanel:SetWidth(154)
	frame.ModeCard:ClearAllPoints()
	frame.ModeCard:SetPoint("TOPLEFT", frame.PanelBackground, "TOPLEFT", 182, -76)
	frame.ModeCard:SetPoint("TOPRIGHT", frame.PanelBackground, "TOPRIGHT", -20, -76)
	frame.PageContainer:ClearAllPoints()
	frame.PageContainer:SetPoint("TOPLEFT", frame.ModeCard, "BOTTOMLEFT", 14, -12)
	frame.PageContainer:SetPoint("BOTTOMRIGHT", frame.PanelBackground, "BOTTOMRIGHT", -34, 24)
	UI.FlatButton(frame.ModeCard.SwitchButton)
	UI.FlatButton(frame.ModeCard.CopyButton)
	UI.CompactModeCard(frame.ModeCard)
end

function UI.CompactModeCard(card)
	card:SetHeight(48)
	card.Title:ClearAllPoints()
	card.Title:SetPoint("TOPLEFT", 14, -8)
	card.Status:ClearAllPoints()
	card.Status:SetPoint("TOPLEFT", card.Title, "BOTTOMLEFT", 0, -3)
	card.Status:SetFontObject(GameFontHighlightSmall)
	card.Description:Hide()
	card.SwitchButton:ClearAllPoints()
	card.SwitchButton:SetPoint("RIGHT", card, "RIGHT", -14, 0)
	card.CopyButton:ClearAllPoints()
	card.CopyButton:SetPoint("RIGHT", card.SwitchButton, "LEFT", -8, 0)
	card:EnableMouse(true)
	card:SetScript("OnEnter", function()
		GameTooltip:SetOwner(card, "ANCHOR_TOP")
		GameTooltip:SetText(card.Title:GetText())
		GameTooltip:AddLine(card.Description:GetText(), 1, 1, 1, true)
		GameTooltip:Show()
	end)
	card:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function UI.CreateTabs(page)
	page.LayoutTab = "general"
	page.LayoutTabs = {}
	local previewCard = CreateFrame("Frame", nil, page.Content, "BackdropTemplate")
	previewCard:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	previewCard:SetBackdropColor(0.045, 0.06, 0.085, 1)
	previewCard:SetBackdropBorderColor(0.15, 0.2, 0.28, 1)
	previewCard:SetHeight(84)
	page.TextPreviewCard = previewCard
	for _, key in ipairs({ "TextPreviewLabel", "TextPreview", "TextOverlayPreview" }) do page[key]:SetParent(previewCard) end
	local labels = { GENERAL, L["settingsBasicLayoutTitle"], L["settingsBasicLookTitle"], L["settingsTextAppearanceTitle"] }
	for index, id in ipairs({ "general", "size", "appearance", "text" }) do
		local button = CreateFrame("Button", nil, page)
		button:SetHeight(32)
		button:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -48)
		local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("TOPLEFT", 6, -3)
		text:SetPoint("BOTTOMRIGHT", -6, 3)
		text:SetText(labels[index])
		button.Label = text
		UI.FlatButton(button)
		button:SetScript("OnClick", function()
			page.LayoutTab = id
			page.ScrollFrame:SetVerticalScroll(0)
			if page.ScrollFrame.ScrollBar then page.ScrollFrame.ScrollBar:SetValue(0) end
			addon.RefreshSettingsFrame("layout")
		end)
		button.tabID = id
		page.LayoutTabs[index] = button
	end
	page.ScrollFrame:ClearAllPoints()
	page.ScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -96)
	page.ScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 0)
	local itemInfo = UI.CreateCheckbox("CheckButton", nil, page.Content)
	itemInfo.Label = itemInfo:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	itemInfo.Label:SetText(L["bagItemInfoOption"])
	itemInfo:SetScript("OnClick", function(self)
		addon.GetSettings().itemInfoTooltip = self:GetChecked() == true
	end)
	itemInfo:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["bagItemInfoOption"])
		GameTooltip:AddLine(L["bagItemInfoOptionDesc"], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	itemInfo:SetScript("OnLeave", function() GameTooltip:Hide() end)
	page.ItemInfoTooltip = itemInfo
	if addon.Bags.EquipmentSets and addon.Bags.EquipmentSets.IsSupported() then
		local checkbox = UI.CreateCheckbox("CheckButton", nil, page.Content)
		checkbox:SetSize(24, 24)
		local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
		label:SetPoint("RIGHT", page.Content, "RIGHT", -12, 0)
		label:SetJustifyH("LEFT")
		label:SetText(L["settingsAutoEquipmentSetCategories"])
		checkbox.Label = label
		local hint = page.Content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		hint:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 28, -4)
		hint:SetPoint("RIGHT", page.Content, "RIGHT", -12, 0)
		hint:SetJustifyH("LEFT")
		hint:SetText(L["settingsAutoEquipmentSetCategoriesDesc"])
		checkbox.Hint = hint
		checkbox:SetScript("OnClick", function(self)
			addon.GetSettings().autoEquipmentSetCategories = self:GetChecked() == true
			addon.MarkCategoryModeStateDirty()
			for _, name in ipairs({ "RequestLayoutUpdate", "RequestBankLayoutUpdate" }) do
				if addon.Bags.functions[name] then addon.Bags.functions[name](true, true) end
			end
			addon.RefreshSettingsFrame("layout")
		end)
		page.AutoEquipmentSets = checkbox
	end
end

function UI.LayoutPairs(page, entries, visible, offset)
	for _, pair in ipairs(entries) do
		local label, control = page[pair[1]], page[pair[2]]
		if label and control then
			label:SetShown(visible)
			control:SetShown(visible)
			if visible then
				control:ClearAllPoints()
				if pair[2]:match("Button$") then control:SetSize(math.min(260, math.max(170, page.TextAppearanceCard:GetWidth() * 0.42)), 26) end
				control:SetPoint("TOPRIGHT", page.TextAppearanceCard, "TOPRIGHT", -14, -offset)
				label:ClearAllPoints()
				label:SetPoint("LEFT", page.TextAppearanceCard, "LEFT", 14, 0)
				label:SetPoint("RIGHT", control, "LEFT", -16, 0)
				label:SetPoint("TOP", control, "TOP", 0, 0)
				label:SetPoint("BOTTOM", control, "BOTTOM", 0, 0)
				label:SetTextColor(0.85, 0.89, 0.95)
				offset = offset + math.max(34, control:GetHeight() + 10, label:GetStringHeight() + 10)
			end
		end
	end
	return offset
end

function UI.LayoutText(page, offset, visible, basic)
	local card = page.TextAppearanceCard
	page.TextStylesTitle:SetShown(visible and not basic)
	page.TextStylesTitle:ClearAllPoints()
	page.TextStylesTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -offset - 8)
	if not basic then offset = offset + page.TextStylesTitle:GetStringHeight() + 20 end
	local available = math.max(240, card:GetWidth() - 28)
	local sizeWidth = UI.sliderSpecs["textElementSize.categoryHeader"] and 260 or 74
	local compact = available < (sizeWidth + 604)
	for _, row in ipairs(page.TextStyleRows or {}) do
		row:SetShown(visible and not basic)
		if not basic then
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -offset)
			row:SetPoint("RIGHT", card, "RIGHT", -14, 0)
			local labelHeight = math.max(16, row.Label:GetStringHeight())
			local controlsTop = labelHeight + 8
			row.Label:SetTextColor(0.85, 0.89, 0.95)
			row.FontButton:ClearAllPoints()
			row.FontButton:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -controlsTop)
			row.FontButton:SetSize(math.min(260, available - (compact and sizeWidth + 10 or sizeWidth + 344)), 26)
			row.SizeStepper:ClearAllPoints()
			row.SizeStepper:SetPoint("LEFT", row.FontButton, "RIGHT", 10, 0)
			row.SizeStepper:SetSize(sizeWidth, 26)
			local selector = row.ElementID == "stackCount" and row.StackAnchorButton or row.CaseButton
			selector:ClearAllPoints()
			selector:SetSize(120, 26)
			if compact then
				selector:SetPoint("TOPLEFT", row.FontButton, "BOTTOMLEFT", 0, -8)
			else
				selector:SetPoint("LEFT", row.SizeStepper, "RIGHT", 10, 0)
			end
			row.OutlineButton:ClearAllPoints()
			row.OutlineButton:SetPoint("LEFT", selector, "RIGHT", 10, 0)
			row.OutlineButton:SetSize(math.min(194, available - 130), 26)
			row:SetHeight(controlsTop + (compact and 60 or 26))
			offset = offset + row:GetHeight() + 16
		end
	end
	local checkbox = page.SubcategoryFullLabels
	checkbox:SetShown(visible and not basic)
	checkbox.Label:SetShown(visible and not basic)
	if not basic then
		checkbox:ClearAllPoints()
		checkbox:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -offset)
		UI.PlaceCheckboxLabel(checkbox, card:GetWidth() - 42)
		offset = offset + math.max(24, checkbox.Label:GetStringHeight()) + 16
	end
	local preview = page.TextPreviewCard
	preview:SetShown(visible)
	preview:ClearAllPoints()
	preview:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 0, -4)
	preview:SetPoint("RIGHT", page.Content, "RIGHT", -4, 0)
	for _, name in ipairs({ "TextPreviewLabel", "TextPreview", "TextOverlayPreview" }) do page[name]:SetShown(visible); page[name]:SetJustifyH("LEFT") end
	UI.PlaceText(page.TextPreviewLabel, preview, 14, 14, 100)
	local previewOffset = UI.PlaceText(page.TextPreview, preview, 130, 14, math.max(100, preview:GetWidth() - 148)) + 8
	previewOffset = UI.PlaceText(page.TextOverlayPreview, preview, 130, previewOffset, math.max(100, preview:GetWidth() - 148))
	preview:SetHeight(previewOffset + 16)
	if visible then
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -12)
		card:SetPoint("RIGHT", page.Content, "RIGHT", -4, 0)
	end
	return offset
end

function UI.LayoutCategories(page)
	local width = math.max(240, math.min(340, math.floor(page:GetWidth() * 0.32), page:GetWidth() - 440))
	page.ListCard:ClearAllPoints()
	page.DetailPanel:ClearAllPoints()
	if page:GetWidth() < 720 then
		page.ListCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -74)
		page.ListCard:SetPoint("RIGHT", page, "RIGHT", -6, 0)
		page.ListCard:SetHeight(230)
		page.DetailPanel:SetPoint("TOPLEFT", page.ListCard, "BOTTOMLEFT", 0, -12)
	else
		page.ListCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -74)
		page.ListCard:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
		page.DetailPanel:SetPoint("TOPLEFT", page.ListCard, "TOPRIGHT", 14, 0)
	end
	page.DetailPanel:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -6, 0)
	page.ListCard:SetWidth(width)
	for index, button in ipairs({ page.AddCategoryButton, page.AddGroupButton, page.TemplateButton }) do
		button:ClearAllPoints()
		button:SetPoint("BOTTOMLEFT", page.ListCard, "BOTTOMLEFT", 12, 12 + ((index - 1) * 32))
		button:SetPoint("RIGHT", page.ListCard, "RIGHT", -12, 0)
		button:SetHeight(24)
	end
	page.ListScrollFrame:ClearAllPoints()
	page.ListScrollFrame:SetPoint("TOPLEFT", page.ListHint, "BOTTOMLEFT", -2, -10)
	page.ListScrollFrame:SetPoint("BOTTOMRIGHT", page.ListCard, "BOTTOMRIGHT", -28, page.TemplateButton and 112 or 80)
end

function UI.ApplyLayout(page)
	UI.SyncSliders(page)
	local tab = page.LayoutTab
	local general, size, appearance, text = tab == "general", tab == "size", tab == "appearance", tab == "text"
	local basic = addon.GetActiveCategoryMode and addon.GetActiveCategoryMode() == "basic"
	local oneBag = addon.GetOneBagMode and addon.GetOneBagMode()
	local width = math.max(100, (page:GetWidth() - 18) / 4)
	for index, button in ipairs(page.LayoutTabs) do
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", page, "TOPLEFT", (index - 1) * (width + 6), -48)
		button:SetWidth(width)
		button:GetNormalTexture():SetVertexColor(tab == button.tabID and 0.16 or 0.07, tab == button.tabID and 0.3 or 0.1, tab == button.tabID and 0.44 or 0.15, 1)
	end
	local offset = 8
	page.GeneralHeadings = page.GeneralHeadings or {}
	for _, id in ipairs({ "contents", "categories", "bank", "window" }) do
		if not page.GeneralHeadings[id] then page.GeneralHeadings[id] = page.Content:CreateFontString(nil, "OVERLAY", "GameFontNormal") end
		page.GeneralHeadings[id]:Hide()
	end
	local function heading(id, label)
		if not general then return end
		local text = page.GeneralHeadings[id]
		if not text then text = page.Content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); page.GeneralHeadings[id] = text end
		text:SetText(label)
		text:ClearAllPoints()
		text:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 14, -offset)
		text:Show()
		offset = offset + text:GetStringHeight() + 12
	end
	heading("contents", L["settingsBagsContentsTitle"])
	local function placeCheckbox(name)
		local button = page[name]
		if button then
			local visible = general and button:IsShown()
			button:SetShown(visible)
			button.Label:SetShown(visible)
			if visible then
				button:SetSize(24, 24)
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 10, -offset)
				button.Label:SetTextColor(0.85, 0.89, 0.95)
				UI.PlaceCheckboxLabel(button, page.Content:GetWidth() - 40)
				offset = offset + math.max(32, button.Label:GetStringHeight() + 8)
			end
		end
	end
	for _, name in ipairs({ "OneBagMode", "OneBagFreeSlotsAtEnd", "ShowFreeSlots", "CombineFreeSlots", "CombineDuplicateItems", "ClearNewItemsOnHeaderClick" }) do placeCheckbox(name) end
	if not oneBag then offset = offset + 12; heading("categories", L["settingsCategoriesLabel"]) end
	for _, name in ipairs({ "ShowCategories", "CompactCategoryLayout", "CategoryTreeView" }) do placeCheckbox(name) end
	if page.AutoEquipmentSets then
		local button = page.AutoEquipmentSets
		button:SetShown(general and not oneBag)
		button.Label:SetShown(general and not oneBag)
		button.Hint:SetShown(general and not oneBag)
		button:SetChecked(addon.GetSettings().autoEquipmentSetCategories == true)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 10, -offset)
		UI.PlaceCheckboxLabel(button, page.Content:GetWidth() - 40)
		if not oneBag then offset = offset + 36 + button.Hint:GetStringHeight() end
	end
	for _, name in ipairs({ "CompactCategoryGapControl", "CategoryTreeIndentControl" }) do
		local control = page[name]
		if control and control.Row then
			control.Row:SetShown(general and not oneBag)
			control.Row:ClearAllPoints()
			control.Row:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 38, -offset)
			control.Row:SetPoint("RIGHT", page.Content, "RIGHT", -14, 0)
			if not oneBag then offset = offset + 32 end
		end
	end
	if general then offset = offset + 16 end
	heading("bank", _G.BANK)
	placeCheckbox("UseIntegratedBank")
	placeCheckbox("RememberLastBankTab")
	if general then offset = offset + 16 end
	heading("window", L["settingsBagsWindowTitle"])
	placeCheckbox("ShowCloseButton")
	if page.ItemInfoTooltip then
		page.ItemInfoTooltip:SetShown(general)
		page.ItemInfoTooltip:SetChecked(addon.GetSettings().itemInfoTooltip == true)
		placeCheckbox("ItemInfoTooltip")
	end
	page.ResetButton:SetShown(general)
	page.ResetButton:ClearAllPoints()
	page.ResetButton:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 14, -offset - 12)
	UI.FlatButton(page.ResetButton)
	page.PaddingCard:SetShown(size)
	page.PaddingCard:ClearAllPoints()
	page.PaddingCard:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 0, -4)
	page.PaddingCard:SetPoint("RIGHT", page.Content, "RIGHT", -4, 0)
	page.TextAppearanceCard:SetShown(appearance or text)
	page.TextAppearanceCard:ClearAllPoints()
	page.TextAppearanceCard:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 0, -4)
	page.TextAppearanceCard:SetPoint("RIGHT", page.Content, "RIGHT", -4, 0)
	page.TextAppearanceTitle:SetText(text and L["settingsTextAppearanceTitle"] or L["settingsBasicLookTitle"])
	page.TextAppearanceHint:SetShown(text)
	UI.LayoutPadding(page, basic)
	local rowOffset = UI.LayoutPairs(page, UI.appearance, appearance, 46)
	local textOffset = UI.LayoutPairs(page, UI.typography, text, math.max(72, 48 + page.TextAppearanceHint:GetStringHeight()))
	local textBottom = UI.LayoutText(page, textOffset, text, basic)
	page.TextAppearanceCard:SetHeight(appearance and rowOffset + 12 or textBottom + 16)
	page.LayoutContentHeight = general and offset + 60 or size and page.PaddingCard:GetHeight() + 16 or page.TextAppearanceCard:GetHeight() + 16
	if text then page.LayoutContentHeight = page.LayoutContentHeight + page.TextPreviewCard:GetHeight() + 12 end
end


-- Apply after dragging so the slider does not move beneath the cursor.
function UI.CreateWindowScale(frame, db)
	local scale = tonumber(db.scale) or 1
	if scale ~= scale then scale = 1 end
	scale = math.max(0.6, math.min(1.2, scale))
	frame:SetScale(scale)
	local slider = CreateFrame("Slider", nil, frame)
	slider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 22)
	slider:SetSize(130, 16); slider:SetOrientation("HORIZONTAL")
	slider:SetMinMaxValues(60, 120); slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetPoint("LEFT", 0, 0); track:SetPoint("RIGHT", 0, 0); track:SetHeight(4); track:SetColorTexture(0.12, 0.17, 0.23, 1)
	slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
	local thumb = slider:GetThumbTexture(); thumb:SetSize(8, 16); thumb:SetVertexColor(0.3, 0.72, 1, 1)
	local caption = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	caption:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 6)
	local function apply(value)
		db.scale = math.max(60, math.min(120, math.floor(value + 0.5))) / 100
		frame:SetScale(db.scale)
	end
	slider:SetScript("OnValueChanged", function(_, value)
		caption:SetText(string.format("%s: %d%%", L["Scale"], math.floor(value + 0.5)))
	end)
	slider:SetScript("OnMouseDown", function() slider.dragging = true end)
	slider:SetScript("OnMouseUp", function() slider.dragging = nil; apply(slider:GetValue()) end)
	slider:SetScript("OnHide", function() if slider.dragging then slider.dragging = nil; apply(slider:GetValue()) end end)
	slider:SetValue(scale * 100)
	frame.ScaleSlider = slider
end

return UI
