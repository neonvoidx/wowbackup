local addon = _G.EnhanceQoL
local UI = addon.Bags.SettingsNavigation
local L = addon.L
UI.sliderSpecs = UI.sliderSpecs or {}
UI.numericTargets = {
	outsideHeaderPadding = "OutsideHeaderPaddingControl", outsideFooterPadding = "OutsideFooterPaddingControl",
	insideHorizontalPadding = "InsideHorizontalPaddingControl", insideTopPadding = "InsideTopPaddingControl", insideBottomPadding = "InsideBottomPaddingControl",
	bagFrameScale = "FrameScaleControl", itemScale = "ItemScaleControl", maxColumns = "MaxColumnsControl", bankMaxColumns = "BankMaxColumnsControl",
	compactCategoryGap = "CompactCategoryGapControl", categoryTreeIndent = "CategoryTreeIndentControl",
	frameBackgroundOpacity = "FrameBackgroundOpacityStepper", frameBorderSize = "FrameBorderSizeStepper", frameBorderOffset = "FrameBorderOffsetStepper",
	textSize = "TextSizeStepper", textOverlaySize = "TextOverlaySizeStepper",
}

-- One numeric definition set serves both settings surfaces, regardless of load order.
function UI.RegisterLayoutSliders(registerSlider, layoutPageID, requestAndRefresh, categoryOptionsEnabled, isBasicCategoryMode, isOneBagModeEnabled)
	registerSlider(layoutPageID, "layout", "compactCategoryGap", "settingsCompactCategoryGapLabel", function()
		return addon.GetCompactCategoryGap and addon.GetCompactCategoryGap() or 8
	end, function(value)
		if addon.SetCompactCategoryGap then addon.SetCompactCategoryGap(value) end
	end, 0, 40, 1, { default = 8, order = 190, isEnabled = function() return categoryOptionsEnabled() and (addon.GetCompactCategoryLayout == nil or addon.GetCompactCategoryLayout()) end, visibleWhen = function() return not isOneBagModeEnabled() end, after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "categoryTreeIndent", "settingsCategoryTreeIndentLabel", function()
		return addon.GetCategoryTreeIndent and addon.GetCategoryTreeIndent() or 14
	end, function(value)
		if addon.SetCategoryTreeIndent then addon.SetCategoryTreeIndent(value) end
	end, 0, 40, 1, { default = 14, order = 210, isEnabled = function() return not isOneBagModeEnabled() and (addon.GetCategoryTreeView and addon.GetCategoryTreeView()) end, visibleWhen = function() return not isOneBagModeEnabled() end, after = function() requestAndRefresh("layout", true, true) end })
	registerSlider(layoutPageID, "layout", "bagFrameScale", "settingsBagFrameScaleLabel", function() return addon.GetBagFrameScale and addon.GetBagFrameScale() or 100 end, addon.SetBagFrameScale, 25, 200, 5, { default = 100, suffix = "%", order = 260, newTagID = "Bags_frameScale", after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "outsideHeaderPadding", "settingsOutsideHeaderPaddingLabel", function() return addon.GetOutsideHeaderPadding and addon.GetOutsideHeaderPadding() or 0 end, addon.SetOutsideHeaderPadding, 0, 24, 1, { default = 0, order = 310, visibleWhen = function() return not isBasicCategoryMode() end, after = function() requestAndRefresh("layout", false) end })
	registerSlider(layoutPageID, "layout", "outsideFooterPadding", "settingsOutsideFooterPaddingLabel", function() return addon.GetOutsideFooterPadding and addon.GetOutsideFooterPadding() or 10 end, addon.SetOutsideFooterPadding, 0, 24, 1, { default = 10, order = 320, visibleWhen = function() return not isBasicCategoryMode() end, after = function() requestAndRefresh("layout", false) end })
	registerSlider(layoutPageID, "layout", "insideHorizontalPadding", "settingsInsideHorizontalPaddingLabel", function() return addon.GetInsideHorizontalPadding and addon.GetInsideHorizontalPadding() or 10 end, addon.SetInsideHorizontalPadding, 0, 24, 1, { default = 10, order = 330, visibleWhen = function() return not isBasicCategoryMode() end, after = function() requestAndRefresh("layout", false) end })
	registerSlider(layoutPageID, "layout", "insideTopPadding", "settingsInsideTopPaddingLabel", function() return addon.GetInsideTopPadding and addon.GetInsideTopPadding() or 10 end, addon.SetInsideTopPadding, 0, 24, 1, { default = 10, order = 340, visibleWhen = function() return not isBasicCategoryMode() end, after = function() requestAndRefresh("layout", false) end })
	registerSlider(layoutPageID, "layout", "insideBottomPadding", "settingsInsideBottomPaddingLabel", function() return addon.GetInsideBottomPadding and addon.GetInsideBottomPadding() or 0 end, addon.SetInsideBottomPadding, 0, 24, 1, { default = 0, order = 350, visibleWhen = function() return not isBasicCategoryMode() end, after = function() requestAndRefresh("layout", false) end })
	registerSlider(layoutPageID, "layout", "itemScale", "settingsItemScaleLabel", function() return addon.GetItemScale and addon.GetItemScale() or 100 end, addon.SetItemScale, 80, 160, 5, { default = 100, suffix = "%", order = 360, after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "maxColumns", "settingsMaxColumnsLabel", function() return addon.GetMaxColumns and addon.GetMaxColumns() or 10 end, addon.SetMaxColumns, 4, 40, 1, { default = 10, order = 370, after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "bankMaxColumns", "settingsBankMaxColumnsLabel", function() return addon.GetBankMaxColumns and addon.GetBankMaxColumns() or 10 end, addon.SetBankMaxColumns, 4, 40, 1, { default = 10, order = 380, newTagID = "Bags_bankMaxColumns", after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "frameBackgroundOpacity", "settingsFrameBackgroundOpacityLabel", function() return addon.GetFrameBackgroundOpacity and addon.GetFrameBackgroundOpacity() or 100 end, addon.SetFrameBackgroundOpacity, 0, 100, 5, { default = 100, suffix = "%", order = 480, after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "frameBorderSize", "settingsFrameBorderSizeLabel", function() return addon.GetFrameBorderSize and addon.GetFrameBorderSize() or 1 end, addon.SetFrameBorderSize, 0, 64, 1, { default = 1, order = 510, after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "frameBorderOffset", "settingsFrameBorderOffsetLabel", function() return addon.GetFrameBorderOffset and addon.GetFrameBorderOffset() or 0 end, addon.SetFrameBorderOffset, -32, 32, 1, { default = 0, order = 520, after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "textSize", "settingsTextSizeLabel", function() local appearance = addon.GetTextAppearance and addon.GetTextAppearance() or {}; return tonumber(appearance.size) or 15 end, addon.SetTextAppearanceSize, 8, 24, 1, { default = 15, order = 620, after = function() requestAndRefresh("layout", true) end })
	registerSlider(layoutPageID, "layout", "textOverlaySize", "settingsTextOverlaySizeLabel", function() return addon.GetTextAppearanceOverlaySize and addon.GetTextAppearanceOverlaySize() or 15 end, addon.SetTextAppearanceOverlaySize, 8, 24, 1, { default = 15, order = 630, after = function() requestAndRefresh("layout", false) end })
	local labels = { categoryHeader = "settingsTextElementCategoryHeader", subcategoryHeader = "settingsTextElementSubcategoryHeader", overlays = "settingsTextElementOverlays", stackCount = "settingsTextElementStackCount" }
	for index, elementID in ipairs({ "categoryHeader", "subcategoryHeader", "overlays", "stackCount" }) do
		local elementLabelKey = labels[elementID]
		local orderBase = 700 + index * 100
		registerSlider(layoutPageID, "layout", "textElementSize." .. elementID, elementLabelKey, function()
			local element = addon.GetTextElementAppearance and addon.GetTextElementAppearance(elementID) or {}
			return tonumber(element.size) or 12
		end, function(value) if addon.SetTextElementSize then addon.SetTextElementSize(elementID, value) end end, 8, 24, 1, { order = orderBase + 20, visibleWhen = function() return not isBasicCategoryMode() end, after = function() requestAndRefresh("layout", true) end })
	end
end

function UI.InitializeStandaloneSliders(after)
	UI.RegisterLayoutSliders(function(_, _, id, _, getter, setter, low, high, step, options)
		UI.sliderSpecs[id] = { get = getter, set = setter, min = low, max = high, step = step, suffix = options.suffix, enabled = options.isEnabled, after = options.after }
	end, "layout", after, function() return addon.GetSettings().showCategories == true and not addon.GetOneBagMode() end,
		function() return addon.GetActiveCategoryMode() == "basic" end, function() return addon.GetOneBagMode() end)
end

function UI.NormalizeNumber(spec, value)
	value = tonumber(value)
	if not value then return nil end
	local step = spec.step or 1
	value = spec.min + math.floor(((value - spec.min) / step) + 0.5) * step
	return math.max(spec.min, math.min(spec.max, value))
end

function UI.SetWidgetEnabled(widget, enabled)
	if widget.SetEnabled then widget:SetEnabled(enabled)
	elseif enabled and widget.Enable then widget:Enable()
	elseif not enabled and widget.Disable then widget:Disable() end
end

function UI.CreateNumeric(parent, spec)
	local control = CreateFrame("Frame", nil, parent)
	control:SetAllPoints()
	local slider = CreateFrame("Slider", nil, control)
	slider:SetPoint("LEFT", 4, 0)
	slider:SetPoint("RIGHT", -72, 0)
	slider:SetHeight(24)
	slider:SetOrientation("HORIZONTAL")
	slider:SetMinMaxValues(spec.min, spec.max)
	slider:SetValueStep(spec.step or 1)
	if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
	local track = addon.PixelUtil.ApplyTexturePixelSnapping(slider:CreateTexture(nil, "BACKGROUND"))
	track:SetPoint("LEFT")
	track:SetPoint("RIGHT")
	track:SetHeight(4)
	track:SetColorTexture(0.2, 0.28, 0.38, 1)
	slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
	local thumb = addon.PixelUtil.ApplyTexturePixelSnapping(slider:GetThumbTexture())
	thumb:SetSize(10, 16)
	thumb:SetVertexColor(0.4, 0.75, 1, 1)
	local input = CreateFrame("EditBox", nil, control, "InputBoxTemplate")
	input:SetSize(58, 24)
	input:SetPoint("RIGHT", -2, 0)
	input:SetAutoFocus(false)
	input:SetJustifyH("CENTER")
	input:SetMaxLetters(10)
	control.Slider, control.Input, control.spec = slider, input, spec
	function control:Sync()
		local value = UI.NormalizeNumber(spec, spec.get and spec.get() or spec.min) or spec.min
		self.updating = true
		slider:SetValue(value)
		if not input:HasFocus() then input:SetText(tostring(value) .. (spec.suffix or "")) end
		local enabled = self.featureEnabled ~= false and (not spec.enabled or spec.enabled())
		UI.SetWidgetEnabled(slider, enabled)
		UI.SetWidgetEnabled(input, enabled)
		self:SetAlpha(enabled and 1 or 0.65)
		self.updating = false
	end
	function control:Commit(value)
		if self.updating or self.featureEnabled == false or (spec.enabled and not spec.enabled()) then return end
		value = UI.NormalizeNumber(spec, value)
		if value and value ~= (spec.get and spec.get()) then
			if spec.set then spec.set(value) end
			if spec.after then spec.after(value) end
		end
		self:Sync()
	end
	slider:SetScript("OnValueChanged", function(_, value) control:Commit(value) end)
	local function commitInput()
		control:Commit((input:GetText() or ""):gsub("%%", ""))
	end
	input:SetScript("OnEnterPressed", function() commitInput(); input:ClearFocus() end)
	input:SetScript("OnEditFocusLost", commitInput)
	input:SetScript("OnEscapePressed", function() control.updating = true; input:ClearFocus(); control.updating = false; control:Sync() end)
	control:Sync()
	return control
end

function UI.AttachNumeric(parent, spec)
	if not parent or not spec then return end
	if not parent.Numeric then
		parent.OldNumericChildren = { parent:GetChildren() }
		parent.OldNumericRegions = { parent:GetRegions() }
		parent.Numeric = UI.CreateNumeric(parent, spec)
	end
	for _, child in ipairs(parent.OldNumericChildren) do child:Hide() end
	for _, region in ipairs(parent.OldNumericRegions) do region:Hide() end
	parent:SetWidth(260)
	parent:SetHeight(26)
	local enabled
	for _, child in ipairs(parent.OldNumericChildren) do
		if child.IsEnabled then enabled = enabled or child:IsEnabled() end
	end
	parent.Numeric.featureEnabled = enabled ~= false
	parent.Numeric:Sync()
end

function UI.SyncSliders(page)
	for id, key in pairs(UI.numericTargets) do
		local target = page[key]
		if target then UI.AttachNumeric(target.Stepper or target, UI.sliderSpecs[id]) end
	end
	for _, row in ipairs(page.TextStyleRows or {}) do
		UI.AttachNumeric(row.SizeStepper, UI.sliderSpecs["textElementSize." .. row.ElementID])
	end
end

function UI.PlaceText(region, parent, x, offset, width)
	region:ClearAllPoints()
	region:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -offset)
	region:SetWidth(math.max(40, width))
	region:SetJustifyH("LEFT")
	region:SetWordWrap(true)
	return offset + math.max(16, region:GetStringHeight())
end

function UI.PlaceCheckboxLabel(button, width)
	UI.PlaceText(button.Label, button, 28, 2, width)
	local textHeight = button.Label:GetStringHeight()
	if textHeight <= button:GetHeight() then
		button.Label:SetPoint("TOPLEFT", button, "TOPLEFT", 28, -(button:GetHeight() - textHeight) / 2)
	end
end

function UI.PlaceCheckbox(button, parent, offset)
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -offset)
	UI.PlaceCheckboxLabel(button, parent:GetWidth() - 36)
	return offset + math.max(24, button.Label:GetStringHeight() + 4) + 10
end

function UI.LayoutPadding(page, basic)
	local offset = 42
	if page.FrameScaleControl then
		UI.PlaceText(page.FrameScaleTitle, page.PaddingCard, 14, 14, page.PaddingCard:GetWidth() - 28)
		UI.PlaceText(page.FrameScaleControl.Label, page.PaddingCard, 14, offset, page.PaddingCard:GetWidth() - 310)
		page.FrameScaleControl.Stepper:ClearAllPoints()
		page.FrameScaleControl.Stepper:SetPoint("TOPRIGHT", page.PaddingCard, "TOPRIGHT", -14, -offset + 4)
		page.FrameScaleControl.Stepper:SetSize(260, 26)
		offset = offset + math.max(36, page.FrameScaleControl.Label:GetStringHeight() + 12) + 12
		UI.PlaceText(page.PaddingTitle, page.PaddingCard, 14, offset, page.PaddingCard:GetWidth() - 28)
		offset = offset + 28
	end
	for _, key in ipairs({ "OutsideHeaderPaddingControl", "OutsideFooterPaddingControl", "InsideHorizontalPaddingControl", "InsideTopPaddingControl", "InsideBottomPaddingControl", "ItemScaleControl", "MaxColumnsControl", "BankMaxColumnsControl" }) do
		local control = page[key]
		local visible = not basic or key == "ItemScaleControl" or key == "MaxColumnsControl" or key == "BankMaxColumnsControl"
		if control and visible then
			UI.PlaceText(control.Label, page.PaddingCard, 14, offset, page.PaddingCard:GetWidth() - 310)
			control.Stepper:ClearAllPoints()
			control.Stepper:SetPoint("TOPRIGHT", page.PaddingCard, "TOPRIGHT", -14, -offset + 4)
			control.Stepper:SetSize(260, 26)
			offset = offset + math.max(36, control.Label:GetStringHeight() + 12)
		end
	end
	page.PaddingCard:SetHeight(offset + 12)
end

function UI.LayoutItemCategory(page, offset)
	local parent, width = page.DetailContent, page.DetailContent:GetWidth()
	local tab = page.automaticEquipmentSet and "appearance" or page.categoryDetailTab or "filter"
	local gap, tabWidth = 6, (width - 12) / 3
	for index, name in ipairs({ "CategoryFilterButton", "CategoryItemsButton", "AdvancedCategoryButton" }) do
		local control = page[name]
		control:SetShown(not page.automaticEquipmentSet)
		control:ClearAllPoints(); control:SetPoint("TOPLEFT", parent, "TOPLEFT", (index - 1) * (tabWidth + gap), -offset)
		control:SetSize(tabWidth, 26)
		local active = ({ "filter", "items", "appearance" })[index] == tab
		if not control.ActiveUnderline then
			control.ActiveUnderline = control:CreateTexture(nil, "OVERLAY")
			control.ActiveUnderline:SetPoint("BOTTOMLEFT", 0, 0)
			control.ActiveUnderline:SetPoint("BOTTOMRIGHT", 0, 0)
			control.ActiveUnderline:SetHeight(2)
			control.ActiveUnderline:SetColorTexture(0.3, 0.72, 1, 1)
		end
		control.ActiveUnderline:SetShown(active)
		local texture = control.GetNormalTexture and control:GetNormalTexture()
		if texture then texture:SetVertexColor(active and 0.16 or 0.07, active and 0.3 or 0.1, active and 0.44 or 0.15, 1) end
	end
	if not page.automaticEquipmentSet then offset = offset + 36 end
	page.RulesCard:SetShown(tab == "filter")
	page.ItemsCard:SetShown(tab == "items")
	for _, spec in ipairs({ { page.RulesCard, "filter" }, { page.ItemsCard, "items" } }) do
		local card = spec[1]
		card:ClearAllPoints(); card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -offset); card:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
		if tab == spec[2] then offset = offset + card:GetHeight() + 12 end
	end
	local visible = tab == "appearance"
	for _, key in ipairs({ "GroupLabel", "GroupButton", "GroupHint", "HideInBags", "DesaturateItems", "PriorityLabel", "PriorityValue", "PriorityDownButton", "PriorityUpButton", "CategoryColorLabel", "CategoryColorSwatch", "CategoryUseClassColor", "PriorityHint", "MatchPriorityLabel", "MatchPriorityValue", "MatchPriorityDownButton", "MatchPriorityUpButton", "MatchPriorityHint", "SortLabel", "SortButton", "SortHint" }) do
		page[key]:SetShown(visible)
		if page[key].Label then page[key].Label:SetShown(visible) end
	end
	if visible then
		offset = UI.PlaceText(page.GroupLabel, parent, 4, offset, width - 12) + 8
		page.GroupButton:ClearAllPoints(); page.GroupButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offset); page.GroupButton:SetSize(math.max(100, width - 12), 26)
		offset = UI.PlaceText(page.GroupHint, parent, 4, offset + 34, width - 12) + 16
		offset = UI.PlaceCheckbox(page.HideInBags, parent, offset)
		offset = UI.PlaceCheckbox(page.DesaturateItems, parent, offset) + 10
		offset = UI.PlaceText(page.PriorityLabel, parent, 4, offset, width - 12) + 8
		page.PriorityValue:ClearAllPoints(); page.PriorityValue:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -offset)
		offset = offset + 34
		page.CategoryColorLabel:ClearAllPoints(); page.CategoryColorLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offset)
		page.CategoryColorSwatch:ClearAllPoints(); page.CategoryColorSwatch:SetPoint("LEFT", page.CategoryColorLabel, "RIGHT", 8, 0)
		offset = UI.PlaceCheckbox(page.CategoryUseClassColor, parent, offset + 26)
		offset = UI.PlaceText(page.PriorityHint, parent, 4, offset, width - 12) + 16
		for _, key in ipairs({ "MatchPriorityLabel", "MatchPriorityValue", "MatchPriorityDownButton", "MatchPriorityUpButton", "MatchPriorityHint" }) do
			page[key]:SetShown(not page.automaticEquipmentSet)
		end
		if not page.automaticEquipmentSet then
			offset = UI.PlaceText(page.MatchPriorityLabel, parent, 4, offset, width - 12) + 8
			page.MatchPriorityValue:ClearAllPoints(); page.MatchPriorityValue:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -offset)
			offset = UI.PlaceText(page.MatchPriorityHint, parent, 4, offset + 30, width - 12) + 16
		end
		offset = UI.PlaceText(page.SortLabel, parent, 4, offset, width - 12) + 8
		page.SortButton:ClearAllPoints(); page.SortButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offset); page.SortButton:SetSize(math.max(100, width - 12), 26)
		offset = UI.PlaceText(page.SortHint, parent, 4, offset + 34, width - 12) + 16
	end
	page.CategoryContentHeight = offset + 24
end

function UI.LayoutCategoryDetails(page, group)
	local parent, width = page.DetailContent, page.DetailContent:GetWidth()
	local offset = UI.PlaceText(page.NameLabel, parent, 4, 8, width - 100) + 8
	page.NameBox:ClearAllPoints()
	page.NameBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offset)
	page.NameBox:SetSize(math.max(100, width - 102), 26)
	page.DeleteCategoryButton:ClearAllPoints()
	page.DeleteCategoryButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -offset)
	page.DeleteCategoryButton:SetSize(82, 26)
	offset = offset + 44
	if not group and page.FilterEditor then UI.LayoutItemCategory(page, offset); return end
	page.CategoryContentHeight = nil
	if not group then
		offset = UI.PlaceText(page.GroupLabel, parent, 4, offset, width - 12) + 8
		page.GroupButton:ClearAllPoints()
		page.GroupButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offset)
		page.GroupButton:SetSize(math.max(100, width - 12), 26)
		offset = UI.PlaceText(page.GroupHint, parent, 4, offset + 34, width - 12) + 16
	end
	offset = UI.PlaceCheckbox(page.HideInBags, parent, offset)
	offset = UI.PlaceCheckbox(page.DesaturateItems, parent, offset) + 10
	UI.PlaceText(page.PriorityLabel, parent, 4, offset, width - 12)
	offset = offset + page.PriorityLabel:GetStringHeight() + 8
	page.PriorityValue:ClearAllPoints()
	page.PriorityValue:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -offset)
	-- The +/- controls keep their existing anchors to the numeric field.
	page.CategoryColorLabel:ClearAllPoints()
	page.CategoryColorLabel:SetPoint("LEFT", page.PriorityUpButton, "RIGHT", 18, 0)
	page.CategoryColorSwatch:ClearAllPoints()
	page.CategoryColorSwatch:SetPoint("LEFT", page.CategoryColorLabel, "RIGHT", 8, 0)
	offset = UI.PlaceCheckbox(page.CategoryUseClassColor, parent, offset + 30)
	offset = UI.PlaceText(page.PriorityHint, parent, 4, offset, width - 12) + 16
	if group then
		offset = UI.PlaceCheckbox(page.GroupSpacerBefore, parent, offset)
		UI.PlaceCheckbox(page.GroupCombineSubcategories, parent, offset)
	else
		offset = UI.PlaceText(page.MatchPriorityLabel, parent, 4, offset, width - 12) + 8
		page.MatchPriorityValue:ClearAllPoints()
		page.MatchPriorityValue:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -offset)
		offset = UI.PlaceText(page.MatchPriorityHint, parent, 4, offset + 30, width - 12) + 16
		offset = UI.PlaceText(page.SortLabel, parent, 4, offset, width - 12) + 8
		page.SortButton:ClearAllPoints()
		page.SortButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offset)
		page.SortButton:SetSize(math.max(100, width - 12), 26)
		UI.PlaceText(page.SortHint, parent, 4, offset + 34, width - 12)
	end
end

function UI.ApplyFlavorPage(id, page)
	if not (addon.variables and addon.variables.isForever) then return end
	if id == "overlays" and page.ShowCraftedQuality then
		page.ShowCraftedQuality:Hide()
		page.ShowCraftedQuality.Label:Hide()
	elseif id == "tracking" then
		page.ShowTrackedCurrencyCharacterBreakdown:Hide()
		page.ShowTrackedCurrencyCharacterBreakdown.Label:Hide()
		page.TrackedCurrencyTooltipCard:Hide()
		page.TrackedCurrencyCard:ClearAllPoints()
		page.TrackedCurrencyCard:SetPoint("TOPLEFT", page.ShowWatchedCurrencies, "BOTTOMLEFT", 0, -24)
		page.TrackedCurrencyCard:SetPoint("RIGHT", page.Content, "RIGHT", -8, 0)
		page.TrackingContentHeight = page.TrackedCurrencyCard:GetHeight() + 80
	end
end

UI.pageLabels = { layout = "settingsCategoryLayout", categories = "settingsCategoriesLabel", overlays = "settingsCategoryOverlays", footer = "settingsCategoryFooter", tracking = "settingsCategoryTracking" }

function UI.TargetTab(key)
	for _, pair in ipairs(UI.appearance) do if pair[1] == key or pair[2] == key then return "appearance" end end
	for _, pair in ipairs(UI.typography) do if pair[1] == key or pair[2] == key then return "text" end end
	if key:find("Text", 1, true) or key:find("SubcategoryFull", 1, true) then return "text" end
	for _, word in ipairs({ "Padding", "FrameScale", "ItemScale", "MaxColumns", "BankMaxColumns" }) do if key:find(word, 1, true) then return "size" end end
	return "general"
end

function UI.SearchTargetSupported(id, key)
	if not (addon.variables and addon.variables.isForever) then return true end
	if id == "overlays" and key == "ShowCraftedQuality" then return false end
	if id == "tracking" and (key:find("Tooltip", 1, true) or key == "ShowTrackedCurrencyCharacterBreakdown") then return false end
	return true
end

function UI.IndexSearch(frame)
	local app = frame.BagsSearchApp
	app:BeginRegistrationBatch()
	frame.BagsSearchRevision = (frame.BagsSearchRevision or 0) + 1
	local revision = frame.BagsSearchRevision
	local function register(pageID, key, target, label, labelRegion, row)
		if type(label) ~= "string" or label:match("^%s*$") or not UI.SearchTargetSupported(pageID, key) then return end
		if not target or not target.GetTop then return end
		local tab = UI.TargetTab(key)
		app:RegisterControl(pageID, {
			id = pageID .. "." .. key, type = "custom", label = label,
			keywords = { L[UI.pageLabels[pageID]] or pageID },
			visibleWhen = function() return frame.BagsSearchRevision == revision end,
			bagsKey = key, bagsTarget = target, bagsTab = tab, bagsPage = pageID, bagsLabel = labelRegion, bagsRow = row,
		})
	end
	for id, page in pairs(frame.Pages) do
		local seen = {}
		local function indexFields(fields, prefix)
			for key, object in pairs(fields) do
				if type(key) == "string" and (type(object) == "table" or type(object) == "userdata") then
					local target, label, labelRegion
					if object.Label and object.Label.GetText then
						target = object.Stepper or object
						label = object.Label:GetText()
						labelRegion = object.Label
					elseif (key:match("Label$") or key:match("Title$")) and key ~= "TextAppearanceTitle" and object.GetText then
						local base = key:gsub("Label$", ""):gsub("Title$", "")
						target = fields[base .. "Button"] or fields[base .. "Box"] or fields[base .. "Stepper"] or fields[base .. "Swatch"] or fields[base .. "Grid"] or fields[base .. "Card"] or object
						label = object:GetText()
						labelRegion = object
					end
					if target and not seen[target] then seen[target] = true; register(id, prefix .. key, target, label, labelRegion) end
				end
			end
		end
		indexFields(page, "")
		for _, card in ipairs(page.Cards or {}) do
			local definition = card.Definition
			if definition then
				register(id, definition.id, card, L[definition.labelKey] or definition.id)
				indexFields(card, definition.id .. ".")
			end
		end
		for _, row in ipairs(page.TextStyleRows or {}) do
			local prefix = "TextStyleRows." .. row.ElementID
			local label = row.Label:GetText()
			register(id, prefix, row, label, row.Label, row)
			for _, field in ipairs({ { "FontButton", "settingsTextFontLabel" }, { "SizeStepper", "settingsTextSizeLabel" }, { "OutlineButton", "settingsTextElementOutlineLabel" }, { row.ElementID == "stackCount" and "StackAnchorButton" or "CaseButton", row.ElementID == "stackCount" and "settingsOverlayAnchorLabel" or "settingsTextCaseLabel" } }) do
				if row[field[1]] then register(id, prefix .. "." .. field[1], row[field[1]], label .. " / " .. (L[field[2]] or field[2]), row.Label, row) end
			end
		end
	end
	app:EndRegistrationBatch()
end

function UI.ScrollToTarget(target)
	local parent = target
	while parent and parent.GetParent do
		if parent.GetObjectType and parent:GetObjectType() == "ScrollFrame" then
			local child = parent:GetScrollChild()
			local childTop, targetTop = child and child:GetTop(), target:GetTop()
			if childTop and targetTop and parent.ScrollBar then
				local low, high = parent.ScrollBar:GetMinMaxValues()
				parent.ScrollBar:SetValue(math.max(low, math.min(high, childTop - targetTop - 16)))
			end
			return
		end
		parent = parent:GetParent()
	end
end

function UI.ClearSearch(frame)
	if frame.BagsSearchInput then
		frame.BagsSearchInput:SetText("")
		frame.BagsSearchInput:ClearFocus()
	end
	if frame.BagsSearchFocus then frame.BagsSearchFocus:Hide() end
end

function UI.ResolveSearchTarget(frame, entry)
	local basic = addon.GetActiveCategoryMode and addon.GetActiveCategoryMode() == "basic"
	local key = entry.bagsKey or ""
	local advanced = entry.bagsPage ~= "layout" and entry.bagsPage ~= "footer"
	if entry.bagsPage == "layout" then
		advanced = key == "ShowCategories" or key:find("PaddingControl", 1, true) or key:find("TextStyleRows", 1, true) or key:find("SubcategoryFull", 1, true)
	end
	if basic and advanced then return frame.ModeCard.SwitchButton, L["settingsCategoryModeSwitchAdvanced"] end
	if entry.bagsPage == "layout" then
		local page = frame.Pages.layout
		local oneBag = addon.GetOneBagMode and addon.GetOneBagMode()
		local hiddenInOneBag = { ShowCategories = true, CombineFreeSlots = true, CombineDuplicateItems = true, ClearNewItemsOnHeaderClick = true, CompactCategoryLayout = true, CategoryTreeView = true, AutoEquipmentSets = true, CompactCategoryGapControl = true, CategoryTreeIndentControl = true }
		if (oneBag and hiddenInOneBag[key]) or (not oneBag and key == "OneBagFreeSlotsAtEnd") then
			return page.OneBagMode, L["settingsOneBagMode"], "general"
		end
	end
end

function UI.CreateSearch(frame, selectPage, createScroll, updateScroll)
	local designer = addon.LibSettingsDesigner
	if not (designer and designer.Config) then return end
	local app = designer.Config:RegisterAddOn("EnhanceQoLBags.Search", { title = L["simpleBagsTitle"], locale = L })
	app:RegisterCategory({ id = "bags", title = L["simpleBagsTitle"] })
	for id, key in pairs(UI.pageLabels) do app:RegisterPage({ id = id, category = "bags", title = L[key] or id }) end
	frame.BagsSearchApp = app
	local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	input:SetPoint("TOPLEFT", frame.ModeCard, "TOPLEFT", 8, 40)
	input:SetPoint("TOPRIGHT", frame.ModeCard, "TOPRIGHT", -8, 40)
	input:SetHeight(26)
	input:SetAutoFocus(false)
	input:SetMaxLetters(160)
	local placeholder = input:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	placeholder:SetPoint("LEFT", 4, 0)
	placeholder:SetText(L["settingsBagsSearchPlaceholder"])
	frame.BagsSearchInput = input
	local panel = CreateFrame("Frame", nil, frame.PageContainer, "BackdropTemplate")
	panel:SetAllPoints()
	panel:SetFrameLevel(frame.PageContainer:GetFrameLevel() + 15)
	panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
	panel:SetBackdropColor(0.025, 0.035, 0.055, 1)
	panel:Hide()
	local scroll, content = createScroll(panel, "BagsSettingsSearchScrollFrame", { contentPaddingRight = 4 })
	scroll:SetPoint("TOPLEFT", 0, -4)
	scroll:SetPoint("BOTTOMRIGHT", -28, 4)
	local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	empty:SetPoint("TOPLEFT", 12, -20)
	empty:SetText(L["settingsBagsSearchEmpty"])
	local rows = {}
	local function search()
		local query = input:GetText() or ""
		placeholder:SetShown(query == "")
		panel:SetShown(query ~= "")
		if query == "" then frame.BagsSearchIndexed = false; return end
		if not frame.BagsSearchIndexed then UI.IndexSearch(frame); frame.BagsSearchIndexed = true end
		local results = app:GetSearchResults(query)
		table.sort(results, function(a, b)
			local order = { layout = 1, categories = 2, overlays = 3, footer = 4, tracking = 5 }
			if a.bagsPage ~= b.bagsPage then return order[a.bagsPage] < order[b.bagsPage] end
			return a.label < b.label
		end)
		for index, entry in ipairs(results) do
			local row = rows[index]
			if not row then
				row = UI.CreateButton("Button", nil, content)
				row:SetHeight(48)
				row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((index - 1) * 50))
				row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
				row:GetFontString():Hide()
				row:GetNormalTexture():SetVertexColor(0.045, 0.065, 0.09, 1)
				row.SearchTitle = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				row.SearchTitle:SetPoint("TOPLEFT", 12, -7)
				row.SearchTitle:SetPoint("TOPRIGHT", row, "TOPRIGHT", -40, -7)
				row.SearchTitle:SetJustifyH("LEFT")
				row.SearchTitle:SetWordWrap(false)
				row.SearchPath = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
				row.SearchPath:SetPoint("TOPLEFT", 12, -28)
				row.SearchPath:SetJustifyH("LEFT")
				local arrow = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				arrow:SetPoint("RIGHT", -12, 0)
				arrow:SetText(">")
				arrow:SetTextColor(0.4, 0.7, 1)
				rows[index] = row
			end
			row.SearchTitle:SetText(entry.label)
			local path = L[UI.pageLabels[entry.bagsPage]] or entry.bagsPage
			if entry.bagsPage == "layout" then
				local tabs = { general = GENERAL, size = L["settingsBasicLayoutTitle"], appearance = L["settingsBasicLookTitle"], text = L["settingsTextAppearanceTitle"] }
				path = path .. " > " .. tabs[entry.bagsTab]
			end
			row.SearchPath:SetText(path)
			row:SetScript("OnClick", function()
				local page = frame.Pages[entry.bagsPage]
				local prerequisite, hint, prerequisiteTab = UI.ResolveSearchTarget(frame, entry)
				UI.ClearSearch(frame)
				if prerequisite == frame.ModeCard.SwitchButton then
					UI.HighlightSearchRow(frame, { bagsTarget = prerequisite })
				else
					if entry.bagsPage == "layout" then page.LayoutTab = prerequisiteTab or entry.bagsTab end
					selectPage(entry.bagsPage)
					local focus = prerequisite and { bagsTarget = prerequisite } or entry
					UI.ScrollToTarget(focus.bagsTarget)
					UI.HighlightSearchRow(frame, focus)
				end
				if prerequisite then
					GameTooltip:SetOwner(prerequisite, "ANCHOR_RIGHT")
					GameTooltip:SetText(entry.label)
					GameTooltip:AddLine(string.format(L["settingsBagsSearchPrerequisite"], hint), 1, 1, 1, true)
					GameTooltip:Show()
				end
			end)
			row:Show()
		end
		for index = #results + 1, #rows do rows[index]:Hide() end
		empty:SetShown(#results == 0)
		updateScroll(scroll, content, #results * 50 + 8)
	end
	input:SetScript("OnTextChanged", search)
	input:SetScript("OnEscapePressed", function() input:SetText(""); input:ClearFocus() end)
end

function UI.HighlightSearchRow(frame, entry)
	local target = entry.bagsRow or entry.bagsTarget
	local parent = target.GetParent and target:GetParent() or target
	if not parent then return end
	local label = entry.bagsLabel or target.Label
	local top = target:GetTop()
	local bottom = target.GetBottom and target:GetBottom() or (top and top - target:GetHeight())
	local parentTop = parent:GetTop()
	if not (top and bottom and parentTop) then return end
	if label and label.GetTop and label:GetTop() then top = math.max(top, label:GetTop()) end
	if label and label.GetBottom and label:GetBottom() then bottom = math.min(bottom, label:GetBottom()) end
	if not frame.BagsSearchFocus then
		local focus = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		focus:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		focus:SetBackdropColor(0.2, 0.5, 0.8, 0.15)
		focus:SetBackdropBorderColor(0.4, 0.8, 1, 0.7)
		focus:EnableMouse(false)
		frame.BagsSearchFocus = focus
	end
	local focus = frame.BagsSearchFocus
	focus:SetParent(parent)
	focus:SetFrameLevel(parent:GetFrameLevel() + 4)
	focus:ClearAllPoints()
	focus:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, top - parentTop + 4)
	focus:SetSize(math.max(40, parent:GetWidth() - 8), math.max(28, top - bottom + 8))
	focus:Show()
	focus.revision = (focus.revision or 0) + 1
	local revision = focus.revision
	C_Timer.After(1.8, function() if focus.revision == revision then focus:Hide() end end)
end

function UI.StyleAnchorButton(button, anchorInfo)
	UI.FlatButton(button)
	button.AnchorBorder = {}
	for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
		local edge = addon.PixelUtil.ApplyTexturePixelSnapping(button:CreateTexture(nil, "BORDER"))
		edge:SetPoint(side, button, side)
		edge:SetSize((side == "TOP" or side == "BOTTOM") and 24 or 1, (side == "TOP" or side == "BOTTOM") and 1 or 24)
		button.AnchorBorder[#button.AnchorBorder + 1] = edge
	end
	local fill = addon.PixelUtil.ApplyTexturePixelSnapping(button:CreateTexture(nil, "ARTWORK"))
	fill:SetAllPoints()
	fill:SetColorTexture(0.2, 0.55, 0.9, 0.35)
	button.SelectedFill = fill
	local dot = addon.PixelUtil.ApplyTexturePixelSnapping(button:CreateTexture(nil, "OVERLAY"))
	dot:SetPoint(anchorInfo.dotPoint, button, anchorInfo.dotPoint, anchorInfo.dotX, anchorInfo.dotY)
	button.Dot = dot
	UI.SetAnchorSelected(button, false)
end

function UI.SetAnchorSelected(button, selected)
	button.SelectedFill:SetShown(selected)
	button.Dot:SetSize(selected and 6 or 4, selected and 6 or 4)
	button.Dot:SetColorTexture(selected and 0.65 or 0.5, selected and 0.9 or 0.6, selected and 1 or 0.7, 1)
	for _, edge in ipairs(button.AnchorBorder) do edge:SetColorTexture(selected and 0.4 or 0.25, selected and 0.8 or 0.34, selected and 1 or 0.44, 1) end
end

function UI.ApplyOverlayEnabledState(card, enabled)
	for _, key in ipairs({ "ColorModeButton", "DisplayModeButton", "ColorSwatch" }) do
		local control = card[key]
		if control then UI.SetWidgetEnabled(control, enabled); control:SetAlpha(enabled and 1 or 0.3) end
	end
	for _, key in ipairs({ "AnchorLabel", "ColorModeLabel", "DisplayModeLabel", "TrackFilterTitle" }) do
		local label = card[key]
		if label then
			label:SetAlpha(1)
			label:SetTextColor(enabled and 1 or 0.45, enabled and 0.82 or 0.5, enabled and 0 or 0.56)
		end
	end
	if card.AnchorValue then card.AnchorValue:SetAlpha(enabled and 1 or 0.4) end
	for _, buttons in ipairs({ card.AnchorButtons or {}, card.TrackButtons or {} }) do
		for _, button in ipairs(buttons) do
			UI.SetWidgetEnabled(button, enabled)
			button:SetAlpha(enabled and 1 or 0.3)
			if button.Label then button.Label:SetAlpha(enabled and 1 or 0.4) end
		end
	end
	if card.PreviewSlot then card.PreviewSlot:SetAlpha(enabled and 1 or 0.25) end
	if card.PreviewSlotIcon and card.PreviewSlotIcon.SetDesaturated then card.PreviewSlotIcon:SetDesaturated(not enabled) end
	if card.PreviewLabel then
		card.PreviewLabel:SetText(enabled and L["settingsOverlayPreviewLabel"] or _G.DISABLED)
		card.PreviewLabel:SetTextColor(enabled and 1 or 0.6, enabled and 0.82 or 0.65, enabled and 0 or 0.7)
	end
	if not card.DisabledHint then
		card.DisabledHint = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		card.DisabledHint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 14, 12)
		card.DisabledHint:SetJustifyH("LEFT")
		card.DisabledHint:SetTextColor(0.65, 0.72, 0.8)
		card.DisabledHint:SetText(string.format(L["settingsOverlayEnableToConfigure"], L["settingsOverlayEnabled"]))
	end
	card.DisabledHint:SetWidth(math.max(100, card:GetWidth() - 28))
	card.DisabledHint:SetShown(not enabled)
end
