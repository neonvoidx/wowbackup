local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

addon.Bags = addon.Bags or {}
addon.Bags.functions = addon.Bags.functions or {}
addon.Bags.variables = addon.Bags.variables or {}

local Bags = addon.Bags
local L = addon.L or {}

local settingsState = addon.Bags.variables.settingsState or {}
addon.Bags.variables.settingsState = settingsState

local MIN_SETTINGS_WIDTH = 652
local MIN_SETTINGS_HEIGHT = 500
local SETTINGS_LAYOUT_SCROLLFRAME_NAME = "BagsSettingsLayoutScrollFrame"
local SETTINGS_LIST_SCROLLFRAME_NAME = "BagsSettingsCategoryListScrollFrame"
local SETTINGS_DETAIL_SCROLLFRAME_NAME = "BagsSettingsCategoryDetailScrollFrame"
local SETTINGS_TRACKING_SCROLLFRAME_NAME = "BagsSettingsTrackingScrollFrame"
local SETTINGS_OVERLAY_SCROLLFRAME_NAME = "BagsSettingsOverlayScrollFrame"
local SETTINGS_ASSIGNED_ITEMS_SCROLLFRAME_NAME = "BagsSettingsAssignedItemsScrollFrame"
local SETTINGS_FOOTER_TRACKED_SCROLLFRAME_NAME = "BagsSettingsFooterTrackedCharactersScrollFrame"
local SETTINGS_TRACKED_CURRENCY_SCROLLFRAME_NAME = "BagsSettingsTrackedCurrencyScrollFrame"
local ASSIGNED_ITEM_ROW_HEIGHT = 28
local ASSIGNED_ITEMS_MAX_VISIBLE_ROWS = 5
local TRACKED_CHARACTER_ROW_HEIGHT = 24
local TRACKED_CURRENCY_ROW_HEIGHT = 26
local CATEGORY_LIST_CHILD_INDENT = 16

local PAGE_ORDER = {
	{
		id = "layout",
		labelKey = "settingsCategoryLayout",
		descriptionKey = "settingsLayoutDescription",
		placeholderText = "L",
		iconTexture = "Interface\\AddOns\\EnhanceQoL\\Modules\\Bags\\Media\\Layout",
		iconSize = 20,
	},
	{
		id = "categories",
		labelKey = "settingsCategoriesLabel",
		descriptionKey = "settingsCategoriesDescription",
		placeholderText = "#",
		iconTexture = "Interface\\AddOns\\EnhanceQoL\\Modules\\Bags\\Media\\Category",
		iconSize = 20,
	},
	{
		id = "overlays",
		labelKey = "settingsCategoryOverlays",
		descriptionKey = "settingsOverlaysDescription",
		placeholderText = "*",
		iconTexture = "Interface\\AddOns\\EnhanceQoL\\Modules\\Bags\\Media\\Overlay",
		iconSize = 20,
	},
	{
		id = "footer",
		labelKey = "settingsCategoryFooter",
		descriptionKey = "settingsFooterDescription",
		placeholderText = "$",
		iconTexture = "Interface\\AddOns\\EnhanceQoL\\Modules\\Bags\\Media\\Currency",
		iconSize = 20,
	},
	{
		id = "tracking",
		labelKey = "settingsCategoryTracking",
		descriptionKey = "settingsTrackingDescription",
		placeholderText = "+",
		iconAtlas = "Waypoint-MapPin-Untracked",
		iconScale = 0.95,
	},
}

local setPageSelection
local refreshLayoutPage
local refreshCategoriesPage
local refreshFooterPage
local refreshTrackingPage
local refreshOverlaysPage
local updateScrollContainer
local createScrollContainer
local refreshSettingsUI
local updateCategoryModeCard
local createCategoryModeOnboardingFrame
local applyLayoutPageMode
local applyFooterPageMode

local BASIC_VISIBLE_PAGE_IDS = {
	layout = true,
	footer = true,
}

local function getSettings()
	return addon.GetSettings and addon.GetSettings() or addon.DB.settings or {}
end

local function getActiveCategoryMode()
	return addon.GetActiveCategoryMode and addon.GetActiveCategoryMode() or "basic"
end

local function isBasicCategoryMode()
	return getActiveCategoryMode() == "basic"
end

local function isOneBagModeEnabled()
	local settings = getSettings()
	return addon.GetOneBagMode and addon.GetOneBagMode() or settings.oneBagMode == true
end

local function isSettingsPageVisibleForMode(pageID)
	if pageID == "categories" and isOneBagModeEnabled() then
		return false
	end

	if not isBasicCategoryMode() then
		return true
	end

	return BASIC_VISIBLE_PAGE_IDS[pageID] == true
end

local function normalizeSettingsPageID(pageID)
	pageID = pageID or settingsState.selectedPage or PAGE_ORDER[1].id
	if isSettingsPageVisibleForMode(pageID) then
		return pageID
	end
	return "layout"
end

local function getOverlayElements()
	return addon.GetOverlayElements and addon.GetOverlayElements() or {}
end

local function getAnchorInfo(anchorID)
	return addon.GetOverlayAnchorInfo and addon.GetOverlayAnchorInfo(anchorID)
end

local function requestBagRefresh(requestRebuild, forceWhenHidden)
	if Bags.functions and Bags.functions.RequestLayoutUpdate then
		Bags.functions.RequestLayoutUpdate(requestRebuild, forceWhenHidden)
	end
	if Bags.functions and Bags.functions.RequestBankLayoutUpdate then
		Bags.functions.RequestBankLayoutUpdate(requestRebuild, forceWhenHidden)
	end
end

local function createQuestLogPanel(frame)
	local panelBackground = frame:CreateTexture(nil, "BACKGROUND")
	panelBackground:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	panelBackground:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
	panelBackground:SetColorTexture(0.02, 0.02, 0.03, 0.58)
	frame.PanelBackground = panelBackground

	local panelShade = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	panelShade:SetPoint("TOPLEFT", panelBackground, "TOPLEFT", 10, -10)
	panelShade:SetPoint("BOTTOMRIGHT", panelBackground, "BOTTOMRIGHT", -10, 10)
	panelShade:SetColorTexture(0, 0, 0, 0.18)
	frame.PanelShade = panelShade

	local borderFrame = CreateFrame("Frame", nil, frame)
	borderFrame:SetPoint("TOPLEFT", -3, 7)
	borderFrame:SetPoint("BOTTOMRIGHT", 3, -6)
	frame.BorderFrame = borderFrame

	local border = borderFrame:CreateTexture(nil, "BORDER")
	border:SetAllPoints()
	border:SetAtlas("questlog-frame", true)
	frame.PanelBorder = border

	local topDetail = borderFrame:CreateTexture(nil, "ARTWORK")
	topDetail:SetAtlas("questlog-frame-filigree", true)
	topDetail:SetPoint("TOP", borderFrame, "TOP", 0, 1)
	frame.PanelTopDetail = topDetail
end

local function createPageHeader(parent, title, description)
	local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	header:SetJustifyH("LEFT")
	header:SetText(title)

	local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
	desc:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetText(description)

	return header, desc
end

local function createCardBackdrop(frame)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0.03, 0.03, 0.04, 0.56)
	frame:SetBackdropBorderColor(0.42, 0.39, 0.27, 0.7)
end

local function clampValue(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end

	return value
end

local function setSingleLineText(textRegion)
	if not textRegion then
		return
	end

	if textRegion.SetWordWrap then
		textRegion:SetWordWrap(false)
	end

	if textRegion.SetMaxLines then
		textRegion:SetMaxLines(1)
	end
end

local function styleInlineMenuButton(button, justifyH)
	if not button then
		return
	end

	local fontString = button.GetFontString and button:GetFontString() or nil
	if not fontString then
		return
	end

	fontString:SetFontObject(GameFontNormalSmall)
	fontString:ClearAllPoints()
	fontString:SetPoint("LEFT", button, "LEFT", (justifyH == "LEFT") and 8 or 4, 0)
	fontString:SetPoint("RIGHT", button, "RIGHT", (justifyH == "LEFT") and -8 or -4, 0)
	fontString:SetJustifyH(justifyH or "CENTER")
	fontString:SetJustifyV("MIDDLE")
	setSingleLineText(fontString)
end

local function setInlineMenuButtonWidth(button, width, justifyH)
	if not button then
		return
	end

	button:SetWidth(math.max(44, math.floor((tonumber(width) or 44) + 0.5)))
	styleInlineMenuButton(button, justifyH)
end

local function getOptionLabel(options, value, fallback)
	for _, option in ipairs(options or {}) do
		if option.value == value then
			return option.label
		end
	end

	return fallback or tostring(value or "")
end

local function createCheckbox(parent, label, tooltipText, x, y, onClick)
	local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	button:SetScript("OnClick", function(self)
		onClick(self:GetChecked())
	end)

	local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("LEFT", button, "RIGHT", 4, 1)
	text:SetJustifyH("LEFT")
	text:SetText(label)
	button.Label = text

	if tooltipText and tooltipText ~= "" then
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(label, 1, 0.82, 0)
			GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	return button
end

local function createInlineCheckbox(parent, label, tooltipText, onClick)
	local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	button:SetSize(24, 24)
	button:SetScript("OnClick", function(self)
		if onClick then
			onClick(self:GetChecked())
		end
	end)

	local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("LEFT", button, "RIGHT", 4, 1)
	text:SetJustifyH("LEFT")
	text:SetText(label)
	button.Label = text

	if tooltipText and tooltipText ~= "" then
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(label, 1, 0.82, 0)
			GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	return button
end

local function setCheckboxEnabledState(button, isEnabled)
	if not button then
		return
	end

	button:SetEnabled(isEnabled)
	if button.Label then
		button.Label:SetAlpha(isEnabled and 1 or 0.45)
	end
end

local function setButtonEnabledState(button, isEnabled)
	if not button then
		return
	end

	button:SetEnabled(isEnabled)
	button:SetAlpha(isEnabled and 1 or 0.45)
end

local function formatTrackedCharacterMoney(amount)
	if type(GetMoneyString) == "function" then
		return GetMoneyString(amount or 0, true)
	elseif C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
		return C_CurrencyInfo.GetCoinTextureString(amount or 0, 12)
	end

	return tostring(amount or 0)
end

local function getTrackedCharacterDisplayName(entry)
	local name = entry and entry.name or UNKNOWN
	local realm = entry and entry.realm
	local currentRealm = GetRealmName and GetRealmName() or nil
	if realm and realm ~= "" and realm ~= currentRealm then
		name = string.format("%s - %s", name, realm)
	end
	if entry and entry.isCurrent then
		name = string.format("%s (%s)", name, L["settingsTrackedCharacterCurrent"] or "Current")
	end
	return name
end

local function getTrackedCharacterColor(entry)
	local classColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	return classColors and entry and entry.class and classColors[entry.class] or nil
end

local function acquireTrackedCharacterRow(page, index)
	page.CharacterRows = page.CharacterRows or {}
	local row = page.CharacterRows[index]
	if row then
		return row
	end

	row = CreateFrame("Frame", nil, page.CharacterListContent)
	row:SetHeight(TRACKED_CHARACTER_ROW_HEIGHT)

	row.NameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.NameText:SetPoint("LEFT", row, "LEFT", 4, 0)
	row.NameText:SetJustifyH("LEFT")

	row.DeleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	row.DeleteButton:SetSize(84, 20)
	row.DeleteButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
	row.DeleteButton:SetText(DELETE or "Delete")
	row.DeleteButton:SetScript("OnClick", function(self)
		if addon.RemoveTrackedCharacterGoldEntry and addon.RemoveTrackedCharacterGoldEntry(self.characterGUID) then
			addon.RefreshSettingsFrame("footer")
		end
	end)

	row.MoneyText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.MoneyText:SetPoint("RIGHT", row.DeleteButton, "LEFT", -8, 0)
	row.MoneyText:SetJustifyH("RIGHT")

	row.NameText:SetPoint("RIGHT", row.MoneyText, "LEFT", -10, 0)

	page.CharacterRows[index] = row
	return row
end

local function setButtonFontObject(button, fontObject, justifyH)
	if not button then
		return
	end

	if fontObject and button.SetNormalFontObject then
		button:SetNormalFontObject(fontObject)
		button:SetHighlightFontObject(fontObject)
	end

	if button.SetDisabledFontObject then
		button:SetDisabledFontObject(GameFontDisableSmall)
	end

	local text = button:GetFontString()
	if text then
		text:SetWordWrap(false)
		if justifyH and text.SetJustifyH then
			text:SetJustifyH(justifyH)
		end
	end
end

local function setTooltipScripts(frame, title, body)
	if not frame then
		return
	end

	if not title or title == "" then
		frame:SetScript("OnEnter", nil)
		frame:SetScript("OnLeave", nil)
		return
	end

	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(title, 1, 0.82, 0)
		if body and body ~= "" then
			GameTooltip:AddLine(body, nil, nil, nil, true)
		end
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

local function setTrackedCurrencyFeedback(page, message, r, g, b)
	if not page or not page.TrackedCurrencyStatus then
		return
	end

	page.TrackedCurrencyStatus:SetText(message or "")
	page.TrackedCurrencyStatus:SetTextColor(r or 1, g or 1, b or 1)
end

local function getTrackedCurrencyEntryColor(entry)
	local qualityColors = ITEM_QUALITY_COLORS
	local color = qualityColors and entry and entry.quality and qualityColors[entry.quality]
	if color then
		return color.r or 1, color.g or 1, color.b or 1
	end

	return 1, 1, 1
end

local function acquireTrackedCurrencyRow(page, index)
	page.TrackedCurrencyRows = page.TrackedCurrencyRows or {}
	local row = page.TrackedCurrencyRows[index]
	if row then
		return row
	end

	row = CreateFrame("Button", nil, page.TrackedCurrencyListContent, "BackdropTemplate")
	row:SetHeight(TRACKED_CURRENCY_ROW_HEIGHT)
	createCardBackdrop(row)

	row.Icon = row:CreateTexture(nil, "ARTWORK")
	row.Icon:SetSize(18, 18)
	row.Icon:SetPoint("LEFT", row, "LEFT", 4, 0)

	row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.Text:SetPoint("LEFT", row.Icon, "RIGHT", 6, 0)
	row.Text:SetJustifyH("LEFT")
	setSingleLineText(row.Text)

	row.RemoveButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	row.RemoveButton:SetSize(58, 18)
	row.RemoveButton:SetPoint("RIGHT", row, "RIGHT", -4, 0)
	row.RemoveButton:SetText(REMOVE)
	setButtonFontObject(row.RemoveButton, GameFontNormalSmall)

	row.DownButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	row.DownButton:SetSize(24, 18)
	row.DownButton:SetPoint("RIGHT", row.RemoveButton, "LEFT", -4, 0)
	row.DownButton:SetText("v")
	setButtonFontObject(row.DownButton, GameFontNormalSmall)

	row.UpButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	row.UpButton:SetSize(24, 18)
	row.UpButton:SetPoint("RIGHT", row.DownButton, "LEFT", -4, 0)
	row.UpButton:SetText("^")
	setButtonFontObject(row.UpButton, GameFontNormalSmall)

	row.Text:SetPoint("RIGHT", row.UpButton, "LEFT", -8, 0)

	row:SetScript("OnEnter", function(self)
		if not self.currencyID then
			return
		end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetCurrencyByID(self.currencyID)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	page.TrackedCurrencyRows[index] = row
	return row
end

local function refreshTrackedCurrencyRows(page)
	if not page or not page.TrackedCurrencyListContent or not page.TrackedCurrencyScrollFrame then
		return
	end

	local entries = addon.GetTrackedCurrencyEntries and addon.GetTrackedCurrencyEntries() or {}
	local previousRow
	local contentHeight = 1

	for index, entry in ipairs(entries) do
		local row = acquireTrackedCurrencyRow(page, index)
		local rowIndex = index
		local currencyID = entry.currencyID
		row:ClearAllPoints()
		if index == 1 then
			row:SetPoint("TOPLEFT", page.TrackedCurrencyListContent, "TOPLEFT", 0, 0)
		else
			row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -4)
		end
		row:SetPoint("RIGHT", page.TrackedCurrencyListContent, "RIGHT", -4, 0)

		row.currencyID = currencyID
		row.Icon:SetTexture(entry.iconFileID or 134400)
		row.Text:SetText(string.format("%s (%d)", entry.name or string.format("ID %d", currencyID), currencyID))
		row.Text:SetTextColor(getTrackedCurrencyEntryColor(entry))

		row.RemoveButton:SetScript("OnClick", function()
			if addon.RemoveTrackedCurrencyID and addon.RemoveTrackedCurrencyID(currencyID) then
				setTrackedCurrencyFeedback(page, "")
				addon.RefreshSettingsFrame("tracking")
				requestBagRefresh(false)
			end
		end)
		row.UpButton:SetScript("OnClick", function()
			if addon.MoveTrackedCurrencyIndex and addon.MoveTrackedCurrencyIndex(rowIndex, -1) then
				setTrackedCurrencyFeedback(page, "")
				addon.RefreshSettingsFrame("tracking")
				requestBagRefresh(false)
			end
		end)
		row.DownButton:SetScript("OnClick", function()
			if addon.MoveTrackedCurrencyIndex and addon.MoveTrackedCurrencyIndex(rowIndex, 1) then
				setTrackedCurrencyFeedback(page, "")
				addon.RefreshSettingsFrame("tracking")
				requestBagRefresh(false)
			end
		end)

		setButtonEnabledState(row.UpButton, index > 1)
		setButtonEnabledState(row.DownButton, index < #entries)
		row:Show()

		previousRow = row
		contentHeight = contentHeight + TRACKED_CURRENCY_ROW_HEIGHT + 4
	end

	for index = #entries + 1, #(page.TrackedCurrencyRows or {}) do
		page.TrackedCurrencyRows[index]:Hide()
	end

	if page.EmptyTrackedCurrenciesText then
		page.EmptyTrackedCurrenciesText:SetShown(#entries == 0)
	end

	if #entries == 0 then
		contentHeight = page.TrackedCurrencyScrollFrame:GetHeight()
	end
	updateScrollContainer(page.TrackedCurrencyScrollFrame, page.TrackedCurrencyListContent, contentHeight)
end

local function tryAddTrackedCurrencyFromPage(page)
	if not page or not page.TrackedCurrencyAddBox then
		return
	end

	local currencyID = tonumber(page.TrackedCurrencyAddBox:GetText())
	if not currencyID or currencyID <= 0 then
		setTrackedCurrencyFeedback(page, L["settingsTrackedCurrencyAddInvalid"] or "Enter a valid currency ID.", 1, 0.25, 0.25)
		return
	end

	local added, reason
	if addon.AddTrackedCurrencyID then
		added, reason = addon.AddTrackedCurrencyID(currencyID)
	end
	if not added then
		if reason == "duplicate" then
			setTrackedCurrencyFeedback(page, L["settingsTrackedCurrencyAddDuplicate"] or "That currency is already tracked.", 1, 0.82, 0)
		else
			setTrackedCurrencyFeedback(page, L["settingsTrackedCurrencyAddInvalid"] or "Enter a valid currency ID.", 1, 0.25, 0.25)
		end
		return
	end

	page.TrackedCurrencyAddBox:SetText("")
	page.TrackedCurrencyAddBox:ClearFocus()
	setTrackedCurrencyFeedback(page, "")
	addon.RefreshSettingsFrame("tracking")
	requestBagRefresh(false)
end

local function attachEditBoxPlaceholder(editBox, text)
	if not editBox or not text or text == "" then
		return
	end

	local placeholder = editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	placeholder:SetPoint("LEFT", editBox, "LEFT", 6, 0)
	placeholder:SetJustifyH("LEFT")
	placeholder:SetText(text)
	editBox.Placeholder = placeholder

	local function updatePlaceholder()
		local currentText = editBox:GetText()
		local hasText = currentText and currentText ~= ""
		placeholder:SetShown(not hasText and not editBox:HasFocus())
	end

	editBox:HookScript("OnEditFocusGained", updatePlaceholder)
	editBox:HookScript("OnEditFocusLost", updatePlaceholder)
	editBox:HookScript("OnTextChanged", updatePlaceholder)
	updatePlaceholder()
end

local function getSettingsFrameDB()
	addon.DB = addon.DB or {}
	addon.DB.settingsFrame = addon.DB.settingsFrame or {}
	return addon.DB.settingsFrame
end

local function getClampedSettingsFrameSize(width, height)
	width = math.max(MIN_SETTINGS_WIDTH, math.floor((tonumber(width) or MIN_SETTINGS_WIDTH) + 0.5))
	height = math.max(MIN_SETTINGS_HEIGHT, math.floor((tonumber(height) or MIN_SETTINGS_HEIGHT) + 0.5))
	return width, height
end

local function saveSettingsFrameSize(frame)
	if not frame then
		return
	end

	local width, height = getClampedSettingsFrameSize(frame:GetSize())
	local settingsFrameDB = getSettingsFrameDB()
	settingsFrameDB.width = width
	settingsFrameDB.height = height
end

updateScrollContainer = function(scrollFrame, scrollChild, contentHeight)
	if not scrollFrame or not scrollChild then
		return
	end

	contentHeight = math.max(contentHeight or 1, scrollFrame:GetHeight() or 1)
	scrollChild:SetHeight(contentHeight)
	scrollFrame:UpdateScrollChildRect()

	local scrollBar = scrollFrame.ScrollBar
	if scrollBar then
		local maxValue = math.max(0, contentHeight - scrollFrame:GetHeight())
		scrollBar:SetMinMaxValues(0, maxValue)
		if scrollBar:GetValue() > maxValue then
			scrollBar:SetValue(maxValue)
		end
		scrollBar:SetShown(maxValue > 0)
	end
end

createScrollContainer = function(parent, name, options)
	options = options or {}

	local scrollFrame = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
	scrollFrame:EnableMouseWheel(true)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetSize(1, 1)
	scrollFrame:SetScrollChild(scrollChild)

	local scrollBar = _G[name .. "ScrollBar"]
	scrollFrame.ScrollBar = scrollBar
	if scrollBar then
		scrollBar:ClearAllPoints()
		if options.scrollbarInside then
			scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -16)
			scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 16)
		else
			scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
			scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
		end
		scrollBar:SetShown(false)
	end

	local function updateWidth()
		local inset = 0
		if scrollBar and scrollBar:IsShown() then
			inset = options.scrollbarInside and 22 or 8
		end

		local basePadding = tonumber(options.contentPaddingRight) or 24
		scrollChild:SetWidth(math.max(1, scrollFrame:GetWidth() - basePadding - inset))
	end

	scrollFrame:HookScript("OnSizeChanged", function()
		updateWidth()
		updateScrollContainer(scrollFrame, scrollChild, scrollChild:GetHeight())
	end)

	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local bar = self.ScrollBar
		if not bar then
			return
		end

		local minValue, maxValue = bar:GetMinMaxValues()
		if maxValue <= 0 then
			return
		end

		local step = 32
		bar:SetValue(math.max(minValue, math.min(maxValue, bar:GetValue() - (delta * step))))
	end)

	updateWidth()
	return scrollFrame, scrollChild
end

local function getCustomCategories()
	return addon.GetCustomCategories and addon.GetCustomCategories() or {}
end

local function getCustomCategoryGroups()
	return addon.GetCustomCategoryGroups and addon.GetCustomCategoryGroups() or {}
end

local function buildCategoriesByGroupID(categories)
	local groupedCategories = {}
	local ungroupedCategories = {}

	for _, category in ipairs(categories or {}) do
		if category.groupID then
			groupedCategories[category.groupID] = groupedCategories[category.groupID] or {}
			groupedCategories[category.groupID][#groupedCategories[category.groupID] + 1] = category
		else
			ungroupedCategories[#ungroupedCategories + 1] = category
		end
	end

	return groupedCategories, ungroupedCategories
end

local function compareCategoryListTopLevelEntries(a, b)
	local aSortOrder = tonumber(a and a.sortOrder) or 0
	local bSortOrder = tonumber(b and b.sortOrder) or 0
	if aSortOrder ~= bSortOrder then
		return aSortOrder < bSortOrder
	end

	return (a and a.name or "") < (b and b.name or "")
end

local function compareCategoryListEntriesBySortOrder(a, b)
	local aSortOrder = tonumber(a and a.sortOrder) or 0
	local bSortOrder = tonumber(b and b.sortOrder) or 0
	if aSortOrder ~= bSortOrder then
		return aSortOrder < bSortOrder
	end

	return (a and a.name or "") < (b and b.name or "")
end

local function setSelectedCategoryEntry(categoryID)
	settingsState.selectedCategoryID = categoryID
	settingsState.selectedGroupID = nil
end

local function setSelectedGroupEntry(groupID)
	settingsState.selectedGroupID = groupID
	settingsState.selectedCategoryID = nil
end

local function getSelectedCustomGroupState()
	local groups = getCustomCategoryGroups()
	if #groups == 0 then
		settingsState.selectedGroupID = nil
		return groups, nil
	end

	for _, group in ipairs(groups) do
		if group.id == settingsState.selectedGroupID then
			return groups, group
		end
	end

	settingsState.selectedGroupID = nil
	return groups, nil
end

local function getSelectedCustomCategoryState()
	local categories = getCustomCategories()
	if settingsState.selectedGroupID or #categories == 0 then
		if #categories == 0 then
			settingsState.selectedCategoryID = nil
		end
		return categories, nil
	end

	for _, category in ipairs(categories) do
		if category.id == settingsState.selectedCategoryID then
			return categories, category
		end
	end

	settingsState.selectedCategoryID = nil
	return categories, nil
end

local function getCategoryPageSelection()
	local groups, selectedGroup = getSelectedCustomGroupState()
	local categories, selectedCategory = getSelectedCustomCategoryState()
	local groupedCategories, ungroupedCategories = buildCategoriesByGroupID(categories)

	if selectedGroup then
		return {
			groups = groups,
			categories = categories,
			groupedCategories = groupedCategories,
			ungroupedCategories = ungroupedCategories,
			selectedType = "group",
			selectedGroup = selectedGroup,
			selectedCategory = nil,
		}
	end

	if selectedCategory then
		return {
			groups = groups,
			categories = categories,
			groupedCategories = groupedCategories,
			ungroupedCategories = ungroupedCategories,
			selectedType = "category",
			selectedGroup = nil,
			selectedCategory = selectedCategory,
		}
	end

	if #groups > 0 then
		setSelectedGroupEntry(groups[1].id)
		return getCategoryPageSelection()
	end

	if #categories > 0 then
		setSelectedCategoryEntry(categories[1].id)
		return getCategoryPageSelection()
	end

	return {
		groups = groups,
		categories = categories,
		groupedCategories = groupedCategories,
		ungroupedCategories = ungroupedCategories,
		selectedType = nil,
		selectedGroup = nil,
		selectedCategory = nil,
	}
end

local function buildCustomCategoryListEntries(groups, categories)
	local groupedCategories, ungroupedCategories = buildCategoriesByGroupID(categories)
	local entries = {}
	local topLevelEntries = {}

	for _, group in ipairs(groups or {}) do
		local childCategories = groupedCategories[group.id] or {}
		topLevelEntries[#topLevelEntries + 1] = {
			type = "group",
			id = group.id,
			name = group.name,
			color = group.color,
			sortOrder = group.sortOrder,
			hidden = group.hidden == true,
			childCategories = childCategories,
		}
	end

	for _, category in ipairs(ungroupedCategories) do
		topLevelEntries[#topLevelEntries + 1] = {
			type = "category",
			id = category.id,
			name = category.name,
			color = category.color,
			priority = category.priority,
			sortOrder = category.sortOrder,
			hidden = category.hidden == true,
			indent = 0,
		}
	end

	table.sort(topLevelEntries, compareCategoryListTopLevelEntries)

	for _, entry in ipairs(topLevelEntries) do
		if entry.type == "group" then
			local childCategories = entry.childCategories or {}
			table.sort(childCategories, compareCategoryListEntriesBySortOrder)
			entries[#entries + 1] = {
				type = "group",
				id = entry.id,
				name = entry.name,
				color = entry.color,
				sortOrder = entry.sortOrder,
				hidden = entry.hidden == true,
			}
			for _, category in ipairs(childCategories) do
				entries[#entries + 1] = {
					type = "category",
					id = category.id,
					name = category.name,
					color = category.color,
					priority = category.priority,
					sortOrder = category.sortOrder,
					hidden = category.hidden == true or entry.hidden == true,
					indent = 1,
				}
			end
		else
			entries[#entries + 1] = entry
		end
	end

	return entries
end

local function copyListValues(values)
	local copy = {}
	for index, value in ipairs(values or {}) do
		copy[index] = value
	end
	return copy
end

local function listContainsValue(values, targetValue)
	for _, value in ipairs(values or {}) do
		if value == targetValue then
			return true
		end
	end
	return false
end

local function toggleListValue(values, targetValue)
	values = copyListValues(values)
	for index, value in ipairs(values) do
		if value == targetValue then
			table.remove(values, index)
			return values
		end
	end
	values[#values + 1] = targetValue
	return values
end

local function requestCategoryRefresh()
	addon.RefreshSettingsFrame()
	requestBagRefresh(true)
end

local function openContextMenu(owner, generator)
	if not owner or not MenuUtil or type(MenuUtil.CreateContextMenu) ~= "function" then
		return
	end

	MenuUtil.CreateContextMenu(owner, generator)
end

local function openColorPicker(initialColor, onChanged)
	if not ColorPickerFrame or type(ColorPickerFrame.SetupColorPickerAndShow) ~= "function" or type(onChanged) ~= "function" then
		return
	end

	local color = initialColor or { 1, 1, 1 }
	local previousR = tonumber(color[1]) or 1
	local previousG = tonumber(color[2]) or 1
	local previousB = tonumber(color[3]) or 1

	local colorInfo = {
		r = previousR,
		g = previousG,
		b = previousB,
		swatchFunc = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			onChanged(r, g, b)
		end,
		cancelFunc = function()
			onChanged(previousR, previousG, previousB)
		end,
	}

	ColorPickerFrame:SetupColorPickerAndShow(colorInfo)
end

local function openSimpleRadioMenu(owner, options, currentValue, onSelect)
	openContextMenu(owner, function(_, rootDescription)
		for _, option in ipairs(options or {}) do
			rootDescription:CreateRadio(
				option.label,
				function(data)
					return currentValue == data.value
				end,
				function(data)
					if onSelect then
						onSelect(data.value)
					end
				end,
				option
			)
		end
	end)
end

local function buildGroupedOptions(options)
	local groupedOrder = {}
	local groupedMap = {}
	local flatOptions = {}

	for _, option in ipairs(options or {}) do
		if option.groupLabel and option.groupLabel ~= "" then
			if not groupedMap[option.groupLabel] then
				groupedMap[option.groupLabel] = {}
				groupedOrder[#groupedOrder + 1] = option.groupLabel
			end
			groupedMap[option.groupLabel][#groupedMap[option.groupLabel] + 1] = option
		else
			flatOptions[#flatOptions + 1] = option
		end
	end

	return flatOptions, groupedOrder, groupedMap
end

local function openCategoryGroupOperatorMenu(owner, categoryID, nodeID, currentOperator)
	openContextMenu(owner, function(_, rootDescription)
		rootDescription:CreateRadio(
			L["settingsCategoryGroupMatchAny"] or "Match any",
			function(data)
				return currentOperator == data
			end,
			function(data)
				if addon.SetCustomCategoryGroupOperator then
					addon.SetCustomCategoryGroupOperator(categoryID, nodeID, data)
				end
				requestCategoryRefresh()
			end,
			"OR"
		)
		rootDescription:CreateRadio(
			L["settingsCategoryGroupMatchAll"] or "Match all",
			function(data)
				return currentOperator == data
			end,
			function(data)
				if addon.SetCustomCategoryGroupOperator then
					addon.SetCustomCategoryGroupOperator(categoryID, nodeID, data)
				end
				requestCategoryRefresh()
			end,
			"AND"
		)
	end)
end

local function openCategoryConditionMenu(owner, categoryID, parentNodeID)
	openContextMenu(owner, function(_, rootDescription)
		for _, optionGroup in ipairs(addon.GetCategoryRuleFieldGroups and addon.GetCategoryRuleFieldGroups() or {}) do
			local submenu = rootDescription:CreateButton(optionGroup.label or ADD)
			for _, field in ipairs(optionGroup.fields or {}) do
				submenu:CreateButton(field.label, function(data)
					if addon.AddCustomCategoryRule then
						addon.AddCustomCategoryRule(categoryID, parentNodeID, data.id)
					end
					requestCategoryRefresh()
				end, field)
			end
		end

		rootDescription:CreateDivider()
		local groupSubmenu = rootDescription:CreateButton(L["settingsCategoryAddLogicGroup"] or "Add logic group")
		groupSubmenu:CreateButton(L["settingsCategoryGroupMatchAny"] or "Match any", function()
			if addon.AddCustomCategoryGroup then
				addon.AddCustomCategoryGroup(categoryID, parentNodeID, "OR")
			end
			requestCategoryRefresh()
		end)
		groupSubmenu:CreateButton(L["settingsCategoryGroupMatchAll"] or "Match all", function()
			if addon.AddCustomCategoryGroup then
				addon.AddCustomCategoryGroup(categoryID, parentNodeID, "AND")
			end
			requestCategoryRefresh()
		end)
	end)
end

local function openCategoryRuleFieldMenu(owner, categoryID, ruleNode)
	openContextMenu(owner, function(_, rootDescription)
		for _, optionGroup in ipairs(addon.GetCategoryRuleFieldGroups and addon.GetCategoryRuleFieldGroups() or {}) do
			local submenu = rootDescription:CreateButton(optionGroup.label or ADD)
			for _, field in ipairs(optionGroup.fields or {}) do
				submenu:CreateButton(field.label, function(data)
					if addon.SetCustomCategoryRuleField then
						addon.SetCustomCategoryRuleField(categoryID, ruleNode.id, data.id)
					end
					requestCategoryRefresh()
				end, field)
			end
		end
	end)
end

local function openCategoryRuleOperatorMenu(owner, categoryID, ruleNode)
	openContextMenu(owner, function(_, rootDescription)
		for _, operatorInfo in ipairs(addon.GetCategoryRuleOperators and addon.GetCategoryRuleOperators(ruleNode) or {}) do
			rootDescription:CreateRadio(
				operatorInfo.label,
				function(data)
					return ruleNode.operator == data
				end,
				function(data)
					if addon.SetCustomCategoryRuleOperator then
						addon.SetCustomCategoryRuleOperator(categoryID, ruleNode.id, data)
					end
					requestCategoryRefresh()
				end,
				operatorInfo.id
			)
		end
	end)
end

local function openCategoryRuleValueMenu(owner, categoryID, ruleNode)
	local valueType = addon.GetCategoryRuleValueType and addon.GetCategoryRuleValueType(ruleNode)
	if valueType == "number" then
		return
	end

	openContextMenu(owner, function(_, rootDescription)
		local options = addon.GetCategoryRuleValueOptions and addon.GetCategoryRuleValueOptions(ruleNode) or {}
		local flatOptions, groupedOrder, groupedMap = buildGroupedOptions(options)

		local function addValueEntries(container, entries)
			for _, option in ipairs(entries or {}) do
				if ruleNode.operator == "IN" then
					container:CreateCheckbox(
						option.label,
						function(data)
							return listContainsValue(ruleNode.value, data.value)
						end,
						function(data)
							if addon.ToggleCustomCategoryRuleListValue then
								addon.ToggleCustomCategoryRuleListValue(categoryID, ruleNode.id, data.value)
							elseif addon.SetCustomCategoryRuleValue then
								addon.SetCustomCategoryRuleValue(categoryID, ruleNode.id, toggleListValue(ruleNode.value, data.value))
							end
							requestCategoryRefresh()
						end,
						option
					)
				else
					container:CreateRadio(
						option.label,
						function(data)
							return ruleNode.value == data.value
						end,
						function(data)
							if addon.SetCustomCategoryRuleValue then
								addon.SetCustomCategoryRuleValue(categoryID, ruleNode.id, data.value)
							end
							requestCategoryRefresh()
						end,
						option
					)
				end
			end
		end

		addValueEntries(rootDescription, flatOptions)

		for _, groupLabel in ipairs(groupedOrder) do
			local submenu = rootDescription:CreateButton(groupLabel)
			addValueEntries(submenu, groupedMap[groupLabel])
		end
	end)
end

local function getCategoryItemDisplayInfo(itemID)
	local itemName, itemLink, itemQuality, _, _, _, _, _, _, iconFileID = GetItemInfo(itemID)
	return {
		name = itemName or string.format("Item %d", itemID),
		link = itemLink,
		quality = itemQuality,
		iconFileID = iconFileID,
	}
end

local function tryAddCursorItemToCategory(categoryID)
	local cursorType, itemID, itemLink = GetCursorInfo()
	if cursorType ~= "item" then
		return false
	end

	local added = addon.AddCustomCategoryItemID and addon.AddCustomCategoryItemID(categoryID, itemLink or itemID)
	if added then
		ClearCursor()
	end
	return added
end

local function acquireCategoryListButton(page, index)
	local button = page.CategoryButtons[index]
	if button then
		return button
	end

	button = CreateFrame("Button", nil, page.ListContent, "BackdropTemplate")
	button:SetHeight(34)
	createCardBackdrop(button)

	local colorBar = button:CreateTexture(nil, "ARTWORK")
	colorBar:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	colorBar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
	colorBar:SetWidth(4)
	button.ColorBar = colorBar

	local indent = button:CreateTexture(nil, "ARTWORK")
	indent:SetSize(10, 1)
	indent:SetColorTexture(0, 0, 0, 0)
	button.Indent = indent

	local priority = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	priority:SetPoint("RIGHT", button, "RIGHT", -10, 0)
	priority:SetJustifyH("RIGHT")
	setSingleLineText(priority)
	button.Priority = priority

	local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	name:SetPoint("LEFT", indent, "RIGHT", 10, 0)
	name:SetPoint("RIGHT", priority, "LEFT", -8, 0)
	name:SetJustifyH("LEFT")
	setSingleLineText(name)
	button.Name = name

	button:SetScript("OnClick", function(self)
		if self.entryType == "group" then
			setSelectedGroupEntry(self.entryID)
		else
			setSelectedCategoryEntry(self.entryID)
		end
		addon.RefreshSettingsFrame("categories")
	end)

	page.CategoryButtons[index] = button
	return button
end

local function acquireBuiltInCategoryToggle(page, index)
	local button = page.BuiltInCategoryButtons[index]
	if button then
		return button
	end

	button = CreateFrame("CheckButton", nil, page.BuiltInContent, "UICheckButtonTemplate")
	button:SetSize(24, 24)

	local colorBar = button:CreateTexture(nil, "ARTWORK")
	colorBar:SetSize(4, 16)
	colorBar:SetPoint("LEFT", button, "LEFT", 24, 0)
	button.ColorBar = colorBar

	local label = page.BuiltInContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", colorBar, "RIGHT", 8, 0)
	label:SetPoint("RIGHT", page.BuiltInContent, "RIGHT", -6, 0)
	label:SetJustifyH("LEFT")
	setSingleLineText(label)
	button.Label = label

	button:SetScript("OnClick", function(self)
		if addon.SetBuiltInCategoryVisible then
			addon.SetBuiltInCategoryVisible(self.categoryID, self:GetChecked())
		end
		requestCategoryRefresh()
	end)

	page.BuiltInCategoryButtons[index] = button
	return button
end

local function acquireAssignedItemRow(page, index)
	local row = page.AssignedItemRows[index]
	if row then
		return row
	end

	row = CreateFrame("Button", nil, page.ItemsListContent, "BackdropTemplate")
	row:SetHeight(24)
	createCardBackdrop(row)

	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("LEFT", row, "LEFT", 4, 0)
	row.Icon = icon

	local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
	text:SetPoint("RIGHT", row, "RIGHT", -64, 0)
	text:SetJustifyH("LEFT")
	setSingleLineText(text)
	row.Text = text

	local removeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	removeButton:SetSize(58, 18)
	removeButton:SetPoint("RIGHT", row, "RIGHT", -4, 0)
	removeButton:SetText(REMOVE)
	row.RemoveButton = removeButton

	row:SetScript("OnEnter", function(self)
		if not self.itemID then
			return
		end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("item:" .. self.itemID)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	page.AssignedItemRows[index] = row
	return row
end

local function acquireRuleNodeFrame(page, index)
	local frame = page.RuleNodeFrames[index]
	if frame then
		return frame
	end

	frame = CreateFrame("Frame", nil, page.RulesContent, "BackdropTemplate")
	createCardBackdrop(frame)

	local accent = frame:CreateTexture(nil, "ARTWORK")
	accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
	accent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
	accent:SetWidth(4)
	frame.Accent = accent

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -6)
	title:SetJustifyH("LEFT")
	setSingleLineText(title)
	frame.Title = title

	local detail = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	detail:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	detail:SetJustifyH("LEFT")
	frame.Detail = detail

	local actionButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	actionButton:SetSize(88, 18)
	setButtonFontObject(actionButton, GameFontNormalSmall)
	frame.ActionButton = actionButton

	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	addButton:SetSize(52, 18)
	addButton:SetText(ADD)
	setButtonFontObject(addButton, GameFontNormalSmall)
	frame.AddButton = addButton

	local fieldButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	fieldButton:SetHeight(18)
	setButtonFontObject(fieldButton, GameFontNormalSmall, "LEFT")
	frame.FieldButton = fieldButton

	local operatorButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	operatorButton:SetHeight(18)
	setButtonFontObject(operatorButton, GameFontNormalSmall)
	frame.OperatorButton = operatorButton

	local valueButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	valueButton:SetHeight(18)
	setButtonFontObject(valueButton, GameFontNormalSmall, "LEFT")
	frame.ValueButton = valueButton

	local valueBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	valueBox:SetHeight(20)
	valueBox:SetAutoFocus(false)
	valueBox:SetNumeric(true)
	valueBox:SetMaxLetters(10)
	valueBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	frame.ValueBox = valueBox

	local removeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	removeButton:SetSize(58, 18)
	removeButton:SetText(REMOVE)
	setButtonFontObject(removeButton, GameFontNormalSmall)
	frame.RemoveButton = removeButton

	page.RuleNodeFrames[index] = frame
	return frame
end

local function setCategoryButtonVisual(button, isSelected, color, entryType, hidden)
	if not button then
		return
	end

	local r = color and color[1] or 0.8
	local g = color and color[2] or 0.8
	local b = color and color[3] or 0.8
	local alpha = hidden and 0.35 or (isSelected and 1 or 0.72)
	button.ColorBar:SetColorTexture(r, g, b, alpha)

	if isSelected then
		button:SetBackdropColor(0.08, 0.08, 0.1, 0.82)
		button:SetBackdropBorderColor(r, g, b, 0.95)
		button.Name:SetTextColor(1, hidden and 0.72 or 0.87, hidden and 0.45 or 0.2)
		if button.Priority then
			button.Priority:SetTextColor(1, 0.87, 0.2)
		end
	else
		button:SetBackdropColor(0.03, 0.03, 0.04, 0.56)
		button:SetBackdropBorderColor(0.42, 0.39, 0.27, 0.7)
		if entryType == "group" then
			button.Name:SetTextColor(1, hidden and 0.62 or 0.87, hidden and 0.45 or 0.2)
		else
			button.Name:SetTextColor(hidden and 0.55 or 0.95, hidden and 0.55 or 0.95, hidden and 0.55 or 0.95)
		end
		if button.Priority then
			button.Priority:SetTextColor(hidden and 0.42 or 0.65, hidden and 0.42 or 0.65, hidden and 0.42 or 0.65)
		end
	end
end

local function layoutCategoryRuleNode(page, categoryID, node, depth, yOffset)
	page.nextRuleNodeFrame = page.nextRuleNodeFrame + 1
	local frame = acquireRuleNodeFrame(page, page.nextRuleNodeFrame)
	local indent = depth * 16

	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", page.RulesContent, "TOPLEFT", indent, -yOffset)
	frame:SetPoint("RIGHT", page.RulesContent, "RIGHT", 0, 0)

	if node.nodeType == "group" then
		local childCount = #(node.children or {})
		frame:SetHeight(40)
		frame.Accent:SetColorTexture(0.94, 0.76, 0.24, 1)

		frame.Title:Show()
		frame.Detail:SetShown(childCount == 0)
		frame.Title:ClearAllPoints()
		frame.Title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -6)
		frame.Title:SetText(addon.GetCategoryGroupLabel and addon.GetCategoryGroupLabel(node.operator) or node.operator)
		frame.Detail:ClearAllPoints()
		frame.Detail:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -2)
		frame.Detail:SetText(childCount == 0 and (L["settingsCategoryNoRules"] or "No automatic rules yet.") or "")

		frame.ActionButton:Show()
		frame.ActionButton:ClearAllPoints()
		frame.ActionButton:SetText(addon.GetCategoryGroupLabel and addon.GetCategoryGroupLabel(node.operator) or node.operator)
		setInlineMenuButtonWidth(frame.ActionButton, 92, "CENTER")
		frame.ActionButton:SetScript("OnClick", function(self)
			openCategoryGroupOperatorMenu(self, categoryID, node.id, node.operator)
		end)

		frame.AddButton:Show()
		frame.AddButton:ClearAllPoints()
		setInlineMenuButtonWidth(frame.AddButton, 52, "CENTER")
		frame.AddButton:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
		frame.AddButton:SetScript("OnClick", function(self)
			openCategoryConditionMenu(self, categoryID, node.id)
		end)

		frame.FieldButton:Hide()
		frame.OperatorButton:Hide()
		frame.ValueButton:Hide()
		frame.ValueBox:Hide()

		if depth > 0 then
			frame.RemoveButton:Show()
			frame.RemoveButton:ClearAllPoints()
			setInlineMenuButtonWidth(frame.RemoveButton, 58, "CENTER")
			frame.RemoveButton:SetPoint("RIGHT", frame.AddButton, "LEFT", -6, 0)
			frame.RemoveButton:SetScript("OnClick", function()
				if addon.RemoveCustomCategoryNode then
					addon.RemoveCustomCategoryNode(categoryID, node.id)
				end
				requestCategoryRefresh()
			end)
			frame.ActionButton:SetPoint("RIGHT", frame.RemoveButton, "LEFT", -6, 0)
		else
			frame.RemoveButton:Hide()
			frame.ActionButton:SetPoint("RIGHT", frame.AddButton, "LEFT", -6, 0)
		end

		local titleRightPadding = 20 + frame.ActionButton:GetWidth() + frame.AddButton:GetWidth()
		if depth > 0 and frame.RemoveButton:IsShown() then
			titleRightPadding = titleRightPadding + frame.RemoveButton:GetWidth() + 6
		end
		frame.Title:SetPoint("RIGHT", frame, "RIGHT", -titleRightPadding, 0)
		setTooltipScripts(frame.ActionButton, frame.ActionButton:GetText(), L["settingsCategoryAutomaticRulesHint"] or "")
		setTooltipScripts(frame.AddButton, ADD, L["settingsCategoryAddLogicGroup"] or "")
		setTooltipScripts(frame.RemoveButton, REMOVE, nil)
	else
		frame:SetHeight(32)
		frame.Accent:SetColorTexture(0.56, 0.79, 0.98, 1)
		frame.Title:Hide()
		frame.Detail:Hide()
		frame.ActionButton:Hide()
		frame.AddButton:Hide()

		local innerWidth = math.max(252, math.floor((frame:GetWidth() > 0 and frame:GetWidth() or ((page.RulesContent:GetWidth() or 420) - indent)) + 0.5))
		local removeWidth = 58
		local gap = 6
		local usableWidth = math.max(196, innerWidth - 18 - removeWidth - (gap * 3))
		local fieldWidth = clampValue(math.floor(usableWidth * 0.42), 128, 220)
		local operatorWidth = clampValue(math.floor(usableWidth * 0.18), 56, 92)

		frame.FieldButton:Show()
		setInlineMenuButtonWidth(frame.FieldButton, fieldWidth, "LEFT")
		frame.FieldButton:ClearAllPoints()
		frame.FieldButton:SetPoint("LEFT", frame, "LEFT", 10, 0)
		frame.FieldButton:SetText(addon.GetCategoryRuleFieldLabel and addon.GetCategoryRuleFieldLabel(node) or tostring(node.field))
		frame.FieldButton:SetScript("OnClick", function(self)
			openCategoryRuleFieldMenu(self, categoryID, node)
		end)
		setTooltipScripts(frame.FieldButton, frame.FieldButton:GetText(), nil)

		frame.OperatorButton:Show()
		setInlineMenuButtonWidth(frame.OperatorButton, operatorWidth, "CENTER")
		frame.OperatorButton:ClearAllPoints()
		frame.OperatorButton:SetPoint("LEFT", frame.FieldButton, "RIGHT", 6, 0)
		frame.OperatorButton:SetText(addon.GetCategoryRuleOperatorLabel and addon.GetCategoryRuleOperatorLabel(node) or "=")
		frame.OperatorButton:SetScript("OnClick", function(self)
			openCategoryRuleOperatorMenu(self, categoryID, node)
		end)
		setTooltipScripts(frame.OperatorButton, frame.OperatorButton:GetText(), nil)

		frame.RemoveButton:Show()
		frame.RemoveButton:ClearAllPoints()
		setInlineMenuButtonWidth(frame.RemoveButton, removeWidth, "CENTER")
		frame.RemoveButton:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
		frame.RemoveButton:SetScript("OnClick", function()
			if addon.RemoveCustomCategoryNode then
				addon.RemoveCustomCategoryNode(categoryID, node.id)
			end
			requestCategoryRefresh()
		end)

		local valueType = addon.GetCategoryRuleValueType and addon.GetCategoryRuleValueType(node) or "enum"
		if valueType == "number" then
			frame.ValueButton:Hide()
			setTooltipScripts(frame.ValueButton, nil, nil)
			frame.ValueBox:Show()
			frame.ValueBox:ClearAllPoints()
			frame.ValueBox:SetPoint("LEFT", frame.OperatorButton, "RIGHT", 6, 0)
			frame.ValueBox:SetPoint("RIGHT", frame.RemoveButton, "LEFT", -6, 0)
			if not frame.ValueBox:HasFocus() then
				frame.ValueBox:SetText(tostring(node.value or 0))
			end
			frame.ValueBox:SetScript("OnEditFocusLost", function(self)
				if addon.SetCustomCategoryRuleValue then
					addon.SetCustomCategoryRuleValue(categoryID, node.id, self:GetText())
				end
				requestCategoryRefresh()
			end)
		else
			frame.ValueBox:Hide()
			frame.ValueButton:Show()
			styleInlineMenuButton(frame.ValueButton, "LEFT")
			frame.ValueButton:ClearAllPoints()
			frame.ValueButton:SetPoint("LEFT", frame.OperatorButton, "RIGHT", 6, 0)
			frame.ValueButton:SetPoint("RIGHT", frame.RemoveButton, "LEFT", -6, 0)
			frame.ValueButton:SetText(addon.GetCategoryRuleValueLabel and addon.GetCategoryRuleValueLabel(node) or tostring(node.value))
			frame.ValueButton:SetScript("OnClick", function(self)
				openCategoryRuleValueMenu(self, categoryID, node)
			end)
			setTooltipScripts(frame.ValueButton, frame.ValueButton:GetText(), nil)
		end

		setTooltipScripts(frame.RemoveButton, REMOVE, nil)
	end

	frame:Show()
	yOffset = yOffset + frame:GetHeight() + 6

	if node.nodeType == "group" then
		for _, child in ipairs(node.children or {}) do
			yOffset = layoutCategoryRuleNode(page, categoryID, child, depth + 1, yOffset)
		end
	end

	return yOffset
end

local function applyAnchorToRegion(region, parent, anchorID, scale)
	local anchorInfo = getAnchorInfo(anchorID)
	if not region or not parent or not anchorInfo then
		return
	end

	local insetScale = scale or 1
	region:ClearAllPoints()
	region:SetPoint(
		anchorInfo.point,
		parent,
		anchorInfo.relativePoint,
		anchorInfo.x * insetScale,
		anchorInfo.y * insetScale
	)

	if region.SetJustifyH and anchorInfo.justifyH then
		region:SetJustifyH(anchorInfo.justifyH)
	end

	if region.SetJustifyV and anchorInfo.justifyV then
		region:SetJustifyV(anchorInfo.justifyV)
	end
end

local function setAnchorOptionVisual(button, isSelected)
	if not button then
		return
	end

	if button.SelectedFill then
		button.SelectedFill:SetShown(isSelected)
	end

	if button.Dot then
		if isSelected then
			button.Dot:SetColorTexture(1, 0.84, 0.2, 1)
			button.Dot:SetSize(6, 6)
		else
			button.Dot:SetColorTexture(0.78, 0.78, 0.78, 1)
			button.Dot:SetSize(5, 5)
		end
	end
end

local function createAnchorOptionButton(parent, elementID, anchorID)
	local anchorInfo = getAnchorInfo(anchorID)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(24, 24)
	button.anchorID = anchorID

	local normal = button:CreateTexture(nil, "BACKGROUND")
	normal:SetAllPoints()
	normal:SetAtlas("common-button-square-gray-up", true)
	button:SetNormalTexture(normal)
	button.NormalTexture = normal

	local pushed = button:CreateTexture(nil, "BACKGROUND", nil, 1)
	pushed:SetAllPoints()
	pushed:SetAtlas("common-button-square-gray-down", true)
	button:SetPushedTexture(pushed)
	button.PushedTexture = pushed

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetAtlas("common-button-square-gray-up", true)
	highlight:SetBlendMode("ADD")
	highlight:SetAlpha(0.45)
	button.HighlightTexture = highlight

	local selectedFill = button:CreateTexture(nil, "OVERLAY", nil, 1)
	selectedFill:SetAllPoints()
	selectedFill:SetColorTexture(1, 0.82, 0.12, 0.2)
	selectedFill:Hide()
	button.SelectedFill = selectedFill

	local centerBox = button:CreateTexture(nil, "ARTWORK")
	centerBox:SetSize(10, 10)
	centerBox:SetPoint("CENTER")
	centerBox:SetColorTexture(0, 0, 0, 0.24)
	button.CenterBox = centerBox

	local dot = button:CreateTexture(nil, "OVERLAY", nil, 2)
	dot:SetSize(5, 5)
	dot:SetPoint(anchorInfo.dotPoint, button, anchorInfo.dotPoint, anchorInfo.dotX, anchorInfo.dotY)
	button.Dot = dot

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L[anchorInfo.labelKey] or self.anchorID, 1, 0.82, 0)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	button:SetScript("OnClick", function(self)
		if addon.SetOverlayElementAnchor then
			addon.SetOverlayElementAnchor(elementID, self.anchorID)
		end
		addon.RefreshSettingsFrame()
		requestBagRefresh(false, true)
	end)

	setAnchorOptionVisual(button, false)
	return button
end

local function refreshOverlayCard(card)
	if not card or not card.Definition then
		return
	end

	local anchorID = addon.GetOverlayElementAnchor and addon.GetOverlayElementAnchor(card.Definition.id) or card.Definition.defaultAnchor
	local anchorInfo = getAnchorInfo(anchorID)
	local isEnabled = addon.IsOverlayElementEnabled and addon.IsOverlayElementEnabled(card.Definition.id)

	if card.AnchorValue then
		card.AnchorValue:SetText(anchorInfo and (L[anchorInfo.labelKey] or anchorID) or anchorID or "")
		card.AnchorValue:SetAlpha(isEnabled and 1 or 0.45)
	end

	if card.PreviewOverlay then
		if card.Definition.previewAtlas then
			local previewSize = tonumber(card.Definition.previewSize) or 22
			card.PreviewOverlay:SetSize(previewSize, previewSize)
			if card.PreviewOverlay.SetAtlas then
				card.PreviewOverlay:SetAtlas(card.Definition.previewAtlas, false)
			end
		else
			local appearance = addon.GetResolvedTextAppearance and addon.GetResolvedTextAppearance() or nil
			local overlaySize = tonumber(appearance and appearance.overlaySize) or tonumber(appearance and appearance.size) or 12
			if addon.ApplyConfiguredFont then
				addon.ApplyConfiguredFont(card.PreviewOverlay, overlaySize)
			end
		end

		if card.Definition.previewAtlas then
			card.PreviewOverlay:SetVertexColor(1, 1, 1, 1)
		elseif card.Definition.id == "upgradeTrack" and addon.GetUpgradeTrackOptions then
			local previewKey
			for _, option in ipairs(addon.GetUpgradeTrackOptions() or {}) do
				if addon.IsUpgradeTrackOverlayTrackEnabled and addon.IsUpgradeTrackOverlayTrackEnabled(option.value) then
					previewKey = option.value
					break
				end
			end

			if previewKey and addon.GetUpgradeTrackColor then
				card.PreviewOverlay:SetText("4/6")
				local r, g, b = addon.GetUpgradeTrackColor(previewKey)
				card.PreviewOverlay:SetTextColor(r or 1, g or 1, b or 1)
			else
				card.PreviewOverlay:SetText(card.Definition.previewText or "")
				if card.Definition.previewColor then
					card.PreviewOverlay:SetTextColor(card.Definition.previewColor[1], card.Definition.previewColor[2], card.Definition.previewColor[3])
				end
			end

		elseif card.Definition.id == "itemLevel" then
			card.PreviewOverlay:SetText(card.Definition.previewText or "")
			if addon.GetOverlayElementColorMode and addon.GetOverlayElementColorMode(card.Definition.id) == "custom" then
				local customColor = addon.GetOverlayElementCustomColor and addon.GetOverlayElementCustomColor(card.Definition.id) or nil
				card.PreviewOverlay:SetTextColor(
					customColor and customColor[1] or 1,
					customColor and customColor[2] or 1,
					customColor and customColor[3] or 1
				)
			elseif card.Definition.previewColor then
				card.PreviewOverlay:SetTextColor(card.Definition.previewColor[1], card.Definition.previewColor[2], card.Definition.previewColor[3])
			else
				card.PreviewOverlay:SetTextColor(1, 1, 1)
			end
		end

		applyAnchorToRegion(card.PreviewOverlay, card.Definition.previewAtlas and card.PreviewSlotIcon or card.PreviewSlot, anchorID, 2)
		card.PreviewOverlay:SetShown(isEnabled)
	end
	if card.EnabledCheck then
		card.EnabledCheck:SetChecked(isEnabled)
	end
	if card.TrackFilterTitle then
		card.TrackFilterTitle:SetAlpha(isEnabled and 1 or 0.45)
	end
	if card.ColorModeButton then
		local colorMode = addon.GetOverlayElementColorMode and addon.GetOverlayElementColorMode(card.Definition.id) or "rarity"
		card.ColorModeButton:SetText(getOptionLabel(
			addon.GetOverlayElementColorModeOptions and addon.GetOverlayElementColorModeOptions(card.Definition.id) or {},
			colorMode,
			L["settingsOverlayColorModeLabel"] or "Item level color"
		))
		setButtonEnabledState(card.ColorModeButton, isEnabled)
	end
	if card.ColorModeLabel then
		card.ColorModeLabel:SetAlpha(isEnabled and 1 or 0.45)
	end
	if card.DisplayModeButton then
		local displayMode = addon.GetOverlayElementDisplayMode and addon.GetOverlayElementDisplayMode(card.Definition.id) or card.Definition.defaultDisplayMode or "icon"
		card.DisplayModeButton:SetText(getOptionLabel(
			addon.GetOverlayElementDisplayModeOptions and addon.GetOverlayElementDisplayModeOptions(card.Definition.id) or {},
			displayMode,
			L["settingsOverlayDisplayModeLabel"] or "Display"
		))
		setButtonEnabledState(card.DisplayModeButton, isEnabled)
	end
	if card.DisplayModeLabel then
		card.DisplayModeLabel:SetAlpha(isEnabled and 1 or 0.45)
	end
	if card.ColorSwatch then
		local customColor = addon.GetOverlayElementCustomColor and addon.GetOverlayElementCustomColor(card.Definition.id) or { 1, 1, 1 }
		card.ColorSwatch:SetColorRGB(customColor[1] or 1, customColor[2] or 1, customColor[3] or 1)
		card.ColorSwatch:SetShown((addon.GetOverlayElementColorMode and addon.GetOverlayElementColorMode(card.Definition.id) or "rarity") == "custom")
		card.ColorSwatch:SetEnabled(isEnabled)
		card.ColorSwatch:SetAlpha(isEnabled and 1 or 0.45)
	end

	for _, button in ipairs(card.AnchorButtons or {}) do
		setAnchorOptionVisual(button, button.anchorID == anchorID)
		button:SetEnabled(isEnabled)
		button:SetAlpha(isEnabled and 1 or 0.45)
	end

	for _, button in ipairs(card.TrackButtons or {}) do
		if addon.IsUpgradeTrackOverlayTrackEnabled then
			button:SetChecked(addon.IsUpgradeTrackOverlayTrackEnabled(button.trackKey))
		end
		setCheckboxEnabledState(button, isEnabled)
	end
end

local function updateOverlayCardLayout(card)
	if not card then
		return
	end

	local descriptionHeight = math.max(14, math.ceil((card.Description and card.Description:GetStringHeight()) or 0))
	local trackRowCount = math.ceil(#(card.TrackButtons or {}) / 2)
	local cardHeight = 208 + descriptionHeight
	if card.DisplayModeButton then
		cardHeight = cardHeight + 34
	end
	if card.ColorModeButton then
		cardHeight = cardHeight + 34
	end

	if trackRowCount > 0 then
		cardHeight = cardHeight + 34 + (trackRowCount * 26)
	end

	cardHeight = math.max(cardHeight, 132)
	card:SetHeight(cardHeight)
end

local function createOverlayAnchorCard(parent, definition)
	local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	createCardBackdrop(card)
	card.Definition = definition
	card.AnchorButtons = {}
	card.TrackButtons = {}

	local trackOptions = definition.trackFilter and (addon.GetUpgradeTrackOptions and addon.GetUpgradeTrackOptions() or {}) or {}

	local title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -16)
	title:SetText(L[definition.labelKey] or definition.id)
	card.Title = title

	local description = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	description:SetPoint("RIGHT", card, "RIGHT", -160, 0)
	description:SetJustifyH("LEFT")
	description:SetJustifyV("TOP")
	description:SetText(L[definition.descriptionKey] or "")
	card.Description = description

	local enabledCheck = createInlineCheckbox(
		card,
		L["settingsOverlayEnabled"] or "Show overlay",
		L["settingsOverlayEnabledTooltip"] or "",
		function(value)
			if addon.SetOverlayElementEnabled then
				addon.SetOverlayElementEnabled(definition.id, value)
			end
			addon.RefreshSettingsFrame()
			requestBagRefresh(false, true)
		end
	)
	enabledCheck:SetPoint("TOPLEFT", description, "BOTTOMLEFT", -4, -8)
	card.EnabledCheck = enabledCheck

	local anchorTopRegion = enabledCheck
	local anchorTopOffsetX = 4
	local anchorTopOffsetY = -12

	if definition.supportsDisplayMode then
		local displayModeLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		displayModeLabel:SetPoint("TOPLEFT", anchorTopRegion, "BOTTOMLEFT", anchorTopOffsetX, anchorTopOffsetY)
		displayModeLabel:SetText(L["settingsOverlayDisplayModeLabel"] or "Display")
		card.DisplayModeLabel = displayModeLabel

		local displayModeButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
		displayModeButton:SetSize(112, 22)
		displayModeButton:SetPoint("LEFT", displayModeLabel, "RIGHT", 8, 0)
		setButtonFontObject(displayModeButton, GameFontNormalSmall)
		displayModeButton:SetScript("OnClick", function(self)
			openSimpleRadioMenu(
				self,
				addon.GetOverlayElementDisplayModeOptions and addon.GetOverlayElementDisplayModeOptions(definition.id) or {},
				addon.GetOverlayElementDisplayMode and addon.GetOverlayElementDisplayMode(definition.id) or definition.defaultDisplayMode,
				function(value)
					if addon.SetOverlayElementDisplayMode and addon.SetOverlayElementDisplayMode(definition.id, value) then
						addon.RefreshSettingsFrame("overlays")
						requestBagRefresh(false, true)
					end
				end
			)
		end)
		card.DisplayModeButton = displayModeButton

		anchorTopRegion = displayModeLabel
		anchorTopOffsetX = 0
		anchorTopOffsetY = -12
	end

	if definition.supportsColorMode then
		local colorModeLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		colorModeLabel:SetPoint("TOPLEFT", anchorTopRegion, "BOTTOMLEFT", anchorTopOffsetX, anchorTopOffsetY)
		colorModeLabel:SetText(L["settingsOverlayColorModeLabel"] or "Item level color")
		card.ColorModeLabel = colorModeLabel

		local colorModeButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
		colorModeButton:SetSize(112, 22)
		colorModeButton:SetPoint("LEFT", colorModeLabel, "RIGHT", 8, 0)
		setButtonFontObject(colorModeButton, GameFontNormalSmall)
		colorModeButton:SetScript("OnClick", function(self)
			openSimpleRadioMenu(
				self,
				addon.GetOverlayElementColorModeOptions and addon.GetOverlayElementColorModeOptions(definition.id) or {},
				addon.GetOverlayElementColorMode and addon.GetOverlayElementColorMode(definition.id) or definition.defaultColorMode,
				function(value)
					if addon.SetOverlayElementColorMode and addon.SetOverlayElementColorMode(definition.id, value) then
						addon.RefreshSettingsFrame("overlays")
						requestBagRefresh(false, true)
					end
				end
			)
		end)
		card.ColorModeButton = colorModeButton

		local colorSwatch = CreateFrame("Button", nil, card, "ColorSwatchTemplate")
		colorSwatch:SetSize(18, 18)
		colorSwatch:SetPoint("LEFT", colorModeButton, "RIGHT", 8, 0)
		colorSwatch:SetScript("OnClick", function()
			local currentColor = addon.GetOverlayElementCustomColor and addon.GetOverlayElementCustomColor(definition.id) or definition.defaultCustomColor or { 1, 1, 1 }
			openColorPicker(currentColor, function(r, g, b)
				if addon.SetOverlayElementCustomColor and addon.SetOverlayElementCustomColor(definition.id, r, g, b) then
					addon.RefreshSettingsFrame("overlays")
					requestBagRefresh(false, true)
				end
			end)
		end)
		colorSwatch:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["settingsOverlayColorModeCustom"] or "Custom", 1, 0.82, 0)
			GameTooltip:AddLine(L["settingsOverlayCustomColorTooltip"] or "Choose the custom color used for this overlay.", nil, nil, nil, true)
			GameTooltip:Show()
		end)
		colorSwatch:HookScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		card.ColorSwatch = colorSwatch

		anchorTopRegion = colorModeLabel
		anchorTopOffsetX = 0
		anchorTopOffsetY = -12
	end

	local anchorLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	anchorLabel:SetPoint("TOPLEFT", anchorTopRegion, "BOTTOMLEFT", anchorTopOffsetX, anchorTopOffsetY)
	anchorLabel:SetText(L["settingsOverlayAnchorLabel"] or "Anchor")
	card.AnchorLabel = anchorLabel

	local anchorValue = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	anchorValue:SetPoint("LEFT", anchorLabel, "RIGHT", 8, 0)
	anchorValue:SetJustifyH("LEFT")
	card.AnchorValue = anchorValue

	local anchorGrid = CreateFrame("Frame", nil, card)
	anchorGrid:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", 0, -12)
	anchorGrid:SetSize(84, 84)
	card.AnchorGrid = anchorGrid

	for index, anchorID in ipairs(addon.GetOverlayAnchorOrder and addon.GetOverlayAnchorOrder() or {}) do
		local button = createAnchorOptionButton(anchorGrid, definition.id, anchorID)
		local row = math.floor((index - 1) / 3)
		local column = (index - 1) % 3
		button:SetPoint("TOPLEFT", anchorGrid, "TOPLEFT", column * 30, -(row * 30))
		card.AnchorButtons[#card.AnchorButtons + 1] = button
	end

	local previewLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	previewLabel:SetPoint("TOPLEFT", card, "TOPRIGHT", -132, -20)
	previewLabel:SetText(L["settingsOverlayPreviewLabel"] or "Preview")
	card.PreviewLabel = previewLabel

	local previewSlot = CreateFrame("Frame", nil, card)
	previewSlot:SetSize(64, 64)
	previewSlot:SetPoint("TOPRIGHT", card, "TOPRIGHT", -24, -42)
	card.PreviewSlot = previewSlot

	local slotBackground = previewSlot:CreateTexture(nil, "ARTWORK")
	slotBackground:SetAllPoints()
	slotBackground:SetAtlas("bags-item-slot64", true)
	card.PreviewSlotBackground = slotBackground

	local slotIcon = previewSlot:CreateTexture(nil, "BORDER")
	slotIcon:SetPoint("TOPLEFT", previewSlot, "TOPLEFT", 6, -6)
	slotIcon:SetPoint("BOTTOMRIGHT", previewSlot, "BOTTOMRIGHT", -6, 6)
	slotIcon:SetTexture("Interface\\Icons\\INV_Sword_04")
	slotIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	card.PreviewSlotIcon = slotIcon

	local previewOverlay
	if definition.previewAtlas then
		previewOverlay = previewSlot:CreateTexture(nil, "OVERLAY", nil, 7)
		previewOverlay:SetSize(tonumber(definition.previewSize) or 22, tonumber(definition.previewSize) or 22)
		if previewOverlay.SetAtlas then
			previewOverlay:SetAtlas(definition.previewAtlas, false)
		end
	else
		previewOverlay = previewSlot:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		if addon.ApplyConfiguredFont then
			addon.ApplyConfiguredFont(previewOverlay, 12)
		else
			previewOverlay:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
		end
		previewOverlay:SetText(definition.previewText or "278")
		if definition.previewColor then
			previewOverlay:SetTextColor(definition.previewColor[1], definition.previewColor[2], definition.previewColor[3])
		end
	end
	card.PreviewOverlay = previewOverlay

	if definition.trackFilter then
		local filterTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		filterTitle:SetPoint("TOPLEFT", anchorGrid, "BOTTOMLEFT", 0, -12)
		filterTitle:SetText(L["settingsOverlayTrackFilterTitle"] or "Visible upgrade tracks")
		card.TrackFilterTitle = filterTitle

		for index, option in ipairs(trackOptions) do
			local button = createInlineCheckbox(card, option.label, "", function(value)
				if addon.SetUpgradeTrackOverlayTrackEnabled then
					addon.SetUpgradeTrackOverlayTrackEnabled(option.value, value)
				end
				addon.RefreshSettingsFrame()
				requestBagRefresh(false, true)
			end)
			button.trackKey = option.value
			local row = math.floor((index - 1) / 2)
			local column = (index - 1) % 2
			button:SetPoint("TOPLEFT", filterTitle, "BOTTOMLEFT", column * 146, -(row * 26) - 8)
			if button.Label then
				button.Label:SetWidth(108)
				button.Label:SetJustifyH("LEFT")
				button.Label:SetWordWrap(false)
			end
			card.TrackButtons[#card.TrackButtons + 1] = button
		end
	end

	updateOverlayCardLayout(card)
	refreshOverlayCard(card)
	return card
end

local function setSideTabVisual(button, isSelected)
	if not button then
		return
	end

	if button.SelectedTexture then
		button.SelectedTexture:SetShown(isSelected)
	end

	if button.Placeholder then
		if isSelected then
			button.Placeholder:SetTextColor(1, 0.87, 0.2)
		else
			button.Placeholder:SetTextColor(0.85, 0.83, 0.74)
		end
	end

	if button.Icon and (button.iconAtlas or button.iconTexture) then
		button.Icon:SetDesaturated(not isSelected)
		button.Icon:SetAlpha(isSelected and 1 or 0.8)
	end
end

local function createSideTabButton(parent, pageInfo)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(43, 55)
	button.pageID = pageInfo.id
	button.tooltipTitle = L[pageInfo.labelKey] or pageInfo.id
	button.tooltipText = L[pageInfo.descriptionKey] or ""
	button.iconAtlas = pageInfo.iconAtlas
	button.iconTexture = pageInfo.iconTexture
	button:RegisterForClicks("LeftButtonUp")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetPoint("CENTER")
	background:SetAtlas("questlog-tab-side", true)
	button.Background = background

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("CENTER", -2, 0)
	button.Icon = icon

	local hasIconAtlas = button.iconAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(button.iconAtlas)
	if hasIconAtlas then
		icon:SetAtlas(button.iconAtlas, true)
		icon:SetScale(pageInfo.iconScale or 1)
	elseif button.iconTexture then
		icon:SetTexture(button.iconTexture)
		icon:SetSize(pageInfo.iconSize or 20, pageInfo.iconSize or 20)
		icon:SetScale(pageInfo.iconScale or 1)
		icon:Show()
	else
		icon:Hide()
		local placeholder = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		placeholder:SetPoint("CENTER", -2, 0)
		placeholder:SetText(pageInfo.placeholderText or "?")
		button.Placeholder = placeholder
	end

	local selectedTexture = button:CreateTexture(nil, "OVERLAY")
	selectedTexture:SetPoint("CENTER")
	selectedTexture:SetAtlas("QuestLog-Tab-side-Glow-select", true)
	selectedTexture:Hide()
	button.SelectedTexture = selectedTexture

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetPoint("CENTER")
	highlight:SetAtlas("QuestLog-Tab-side-Glow-hover", true)
	button.HighlightTexture = highlight

	button:SetScript("OnMouseDown", function(self, mouseButton)
		if mouseButton ~= "LeftButton" then
			return
		end

		if self.Icon and self.Icon:IsShown() then
			self.Icon:SetPoint("CENTER", -1, -1)
		end
		if self.Placeholder then
			self.Placeholder:SetPoint("CENTER", -1, -1)
		end
	end)

	button:SetScript("OnMouseUp", function(self, mouseButton)
		if mouseButton ~= "LeftButton" then
			return
		end

		if self.Icon and self.Icon:IsShown() then
			self.Icon:SetPoint("CENTER", -2, 0)
		end
		if self.Placeholder then
			self.Placeholder:SetPoint("CENTER", -2, 0)
		end

		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
	end)

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT", 4, -4)
		GameTooltip:SetText(self.tooltipTitle, 1, 0.82, 0)
		if self.tooltipText and self.tooltipText ~= "" then
			GameTooltip:AddLine(self.tooltipText, nil, nil, nil, true)
		end
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function(self)
		setPageSelection(self.pageID)
		addon.RefreshSettingsFrame(self.pageID)
	end)

	button.SetSelected = setSideTabVisual
	setSideTabVisual(button, false)

	return button
end

refreshFooterPage = function(page, settings)
	if not page then
		return
	end

	applyFooterPageMode(page)

	page.ShowGold:SetChecked(settings.showGold)
	if page.MoneyFormatButton then
		local moneyFormat = addon.GetMoneyFormat and addon.GetMoneyFormat() or "symbols"
		page.MoneyFormatButton:SetText(getOptionLabel(addon.GetMoneyFormatOptions and addon.GetMoneyFormatOptions() or {}, moneyFormat, L["settingsMoneyFormatLabel"] or "Money format"))
		page.MoneyFormatButton:SetEnabled(settings.showGold)
		page.MoneyFormatButton:SetAlpha(settings.showGold and 1 or 0.45)
	end
	if page.MoneyFormatLabel then
		page.MoneyFormatLabel:SetAlpha(settings.showGold and 1 or 0.45)
	end
	page.ShowCurrencies:SetChecked(settings.showCurrencies)
	page.ShowFooterSlotSummary:SetChecked(settings.showFooterSlotSummary)
	if page.FooterSummaryPaddingValue then
		local padding = addon.GetFooterSummaryPadding and addon.GetFooterSummaryPadding() or 0
		page.FooterSummaryPaddingValue:SetText(tostring(padding))
	end
	if page.FooterSummaryPaddingDownButton and page.FooterSummaryPaddingUpButton then
		local padding = addon.GetFooterSummaryPadding and addon.GetFooterSummaryPadding() or 0
		local enabled = settings.showFooterSlotSummary ~= false
		page.FooterSummaryPaddingDownButton:SetEnabled(enabled and padding > 0)
		page.FooterSummaryPaddingUpButton:SetEnabled(enabled and padding < 24)
		page.FooterSummaryPaddingDownButton:SetAlpha(enabled and 1 or 0.45)
		page.FooterSummaryPaddingUpButton:SetAlpha(enabled and 1 or 0.45)
	end
	if page.FooterSummaryPaddingLabel then
		page.FooterSummaryPaddingLabel:SetAlpha(settings.showFooterSlotSummary ~= false and 1 or 0.5)
	end
	if page.FooterSummaryPaddingHint then
		page.FooterSummaryPaddingHint:SetAlpha(settings.showFooterSlotSummary ~= false and 1 or 0.5)
	end

	local entries = addon.GetTrackedCharacterGoldEntries and addon.GetTrackedCharacterGoldEntries() or {}
	local previousRow
	local contentHeight = 1

	for index, entry in ipairs(entries) do
		local row = acquireTrackedCharacterRow(page, index)
		row:ClearAllPoints()
		if index == 1 then
			row:SetPoint("TOPLEFT", page.CharacterListContent, "TOPLEFT", 0, 0)
		else
			row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -4)
		end
		row:SetPoint("RIGHT", page.CharacterListContent, "RIGHT", -4, 0)

		row.NameText:SetText(getTrackedCharacterDisplayName(entry))
		local color = getTrackedCharacterColor(entry)
		if color then
			row.NameText:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
		else
			row.NameText:SetTextColor(1, 1, 1)
		end
		row.MoneyText:SetText(formatTrackedCharacterMoney(entry.money))
		row.DeleteButton.characterGUID = entry.isCurrent and nil or entry.guid
		row.DeleteButton:SetText(entry.isCurrent and (L["settingsTrackedCharacterCurrent"] or "Current") or (DELETE or "Delete"))
		row.DeleteButton:SetEnabled(not entry.isCurrent)
		row.DeleteButton:SetAlpha(entry.isCurrent and 0.45 or 1)
		row:Show()

		previousRow = row
		contentHeight = contentHeight + TRACKED_CHARACTER_ROW_HEIGHT + 4
	end

	for index = #entries + 1, #(page.CharacterRows or {}) do
		page.CharacterRows[index]:Hide()
	end

	if page.EmptyTrackedCharactersText then
		page.EmptyTrackedCharactersText:SetShown(#entries == 0)
	end

	if page.CharacterListScrollFrame and page.CharacterListContent then
		if #entries == 0 then
			contentHeight = page.CharacterListScrollFrame:GetHeight()
		end
		updateScrollContainer(page.CharacterListScrollFrame, page.CharacterListContent, contentHeight)
	end
end

refreshTrackingPage = function(page, settings)
	if not page then
		return
	end

	page.ShowWatchedCurrencies:SetChecked(settings.showWatchedCurrencies)
	page.ShowTrackedCurrencyCharacterBreakdown:SetChecked(settings.showTrackedCurrencyCharacterBreakdown == true)

	local tooltipOptionsEnabled = settings.showTrackedCurrencyCharacterBreakdown == true
	if page.TrackedCurrencyTooltipTotalPositionButton then
		page.TrackedCurrencyTooltipTotalPositionButton:SetText(getOptionLabel(
			addon.GetTrackedCurrencyTooltipTotalPositionOptions and addon.GetTrackedCurrencyTooltipTotalPositionOptions() or {},
			addon.GetTrackedCurrencyTooltipTotalPosition and addon.GetTrackedCurrencyTooltipTotalPosition() or "top",
			L["settingsTrackedCurrencyTooltipTotalPositionLabel"] or "Total position"
		))
		setButtonEnabledState(page.TrackedCurrencyTooltipTotalPositionButton, tooltipOptionsEnabled)
	end
	if page.TrackedCurrencyTooltipNameColorButton then
		page.TrackedCurrencyTooltipNameColorButton:SetText(getOptionLabel(
			addon.GetTrackedCurrencyTooltipColorModeOptions and addon.GetTrackedCurrencyTooltipColorModeOptions() or {},
			addon.GetTrackedCurrencyTooltipNameColorMode and addon.GetTrackedCurrencyTooltipNameColorMode() or "default",
			L["settingsTrackedCurrencyTooltipNameColorLabel"] or "Name color"
		))
		setButtonEnabledState(page.TrackedCurrencyTooltipNameColorButton, tooltipOptionsEnabled)
	end
	if page.TrackedCurrencyTooltipCountColorButton then
		page.TrackedCurrencyTooltipCountColorButton:SetText(getOptionLabel(
			addon.GetTrackedCurrencyTooltipColorModeOptions and addon.GetTrackedCurrencyTooltipColorModeOptions() or {},
			addon.GetTrackedCurrencyTooltipCountColorMode and addon.GetTrackedCurrencyTooltipCountColorMode() or "default",
			L["settingsTrackedCurrencyTooltipCountColorLabel"] or "Count color"
		))
		setButtonEnabledState(page.TrackedCurrencyTooltipCountColorButton, tooltipOptionsEnabled)
	end

	for _, region in ipairs({
		page.TrackedCurrencyTooltipCard,
		page.TrackedCurrencyTooltipTitle,
		page.TrackedCurrencyTooltipHint,
		page.TrackedCurrencyTooltipTotalPositionLabel,
		page.TrackedCurrencyTooltipNameColorLabel,
		page.TrackedCurrencyTooltipCountColorLabel,
	}) do
		if region and region.SetAlpha then
			region:SetAlpha(tooltipOptionsEnabled and 1 or 0.5)
		end
	end

	refreshTrackedCurrencyRows(page)
	if page.ScrollFrame and page.Content then
		updateScrollContainer(page.ScrollFrame, page.Content, page.TrackingContentHeight or 528)
	end
end

setPageSelection = function(pageID)
	pageID = normalizeSettingsPageID(pageID)
	settingsState.selectedPage = pageID

	local frame = settingsState.frame
	if not frame then
		return
	end

	for _, button in ipairs(frame.PageButtons or {}) do
		local isSelected = button.pageID == pageID
		if button.SetSelected then
			button:SetSelected(isSelected)
		end
	end

	for id, page in pairs(frame.Pages or {}) do
		page:SetShown(id == pageID)
	end
end

local function createCategoriesPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints()
	page.CategoryButtons = {}
	page.BuiltInCategoryButtons = {}
	page.AssignedItemRows = {}
	page.RuleNodeFrames = {}

	createPageHeader(
		page,
		L["settingsCategoriesLabel"] or "Categories",
		L["settingsCategoriesDescription"] or "Create parent groups and rule-based categories for Advanced mode."
	)

	local leftColumnWidth = 220

	local builtInCard = CreateFrame("Frame", nil, page, "BackdropTemplate")
	builtInCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -74)
	builtInCard:SetWidth(leftColumnWidth)
	builtInCard:SetHeight(232)
	createCardBackdrop(builtInCard)
	builtInCard:Hide()
	page.BuiltInCard = builtInCard

	local builtInTitle = builtInCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	builtInTitle:SetPoint("TOPLEFT", builtInCard, "TOPLEFT", 14, -14)
	builtInTitle:SetText(L["settingsBuiltInCategoriesTitle"] or "Default groups")
	page.BuiltInTitle = builtInTitle

	local builtInHint = builtInCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	builtInHint:SetPoint("TOPLEFT", builtInTitle, "BOTTOMLEFT", 0, -4)
	builtInHint:SetPoint("RIGHT", builtInCard, "RIGHT", -14, 0)
	builtInHint:SetJustifyH("LEFT")
	builtInHint:SetJustifyV("TOP")
	builtInHint:SetText(L["settingsBuiltInCategoriesHint"] or "Hide any built-in section you do not want to keep.")
	page.BuiltInHint = builtInHint

	local builtInContent = CreateFrame("Frame", nil, builtInCard)
	builtInContent:SetPoint("TOPLEFT", builtInHint, "BOTTOMLEFT", 0, -10)
	builtInContent:SetPoint("BOTTOMRIGHT", builtInCard, "BOTTOMRIGHT", -10, 12)
	page.BuiltInContent = builtInContent

	local listCard = CreateFrame("Frame", nil, page, "BackdropTemplate")
	listCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -74)
	listCard:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
	listCard:SetWidth(leftColumnWidth)
	createCardBackdrop(listCard)
	page.ListCard = listCard

	local listTitle = listCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	listTitle:SetPoint("TOPLEFT", listCard, "TOPLEFT", 14, -14)
	listTitle:SetText(L["settingsManagedCategoriesTitle"] or L["settingsCategoriesLabel"] or "Categories")
	page.ListTitle = listTitle

	local listHint = listCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	listHint:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", 0, -4)
	listHint:SetPoint("RIGHT", listCard, "RIGHT", -14, 0)
	listHint:SetJustifyH("LEFT")
	listHint:SetJustifyV("TOP")
	listHint:SetText(L["settingsManagedCategoriesHint"] or "Create parent groups and rule-based categories for the active mode.")
	page.ListHint = listHint

	local listScrollFrame, listContent = createScrollContainer(listCard, SETTINGS_LIST_SCROLLFRAME_NAME)
	listScrollFrame:SetPoint("TOPLEFT", listHint, "BOTTOMLEFT", -2, -10)
	listScrollFrame:SetPoint("BOTTOMRIGHT", listCard, "BOTTOMRIGHT", -28, 44)
	page.ListScrollFrame = listScrollFrame
	page.ListContent = listContent

	local emptyListText = listContent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	emptyListText:SetPoint("TOPLEFT", listContent, "TOPLEFT", 4, -8)
	emptyListText:SetPoint("BOTTOMRIGHT", listContent, "BOTTOMRIGHT", -4, 8)
	emptyListText:SetJustifyH("CENTER")
	emptyListText:SetJustifyV("MIDDLE")
	emptyListText:SetText(L["settingsCategoriesEmptyState"] or "Create a group or category to start building your Advanced layout.")
	page.EmptyListText = emptyListText

	local addGroupButton = CreateFrame("Button", nil, listCard, "UIPanelButtonTemplate")
	addGroupButton:SetSize(92, 22)
	addGroupButton:SetPoint("BOTTOMLEFT", listCard, "BOTTOMLEFT", 14, 14)
	addGroupButton:SetText(L["settingsCategoryAddGroup"] or "Add group")
	addGroupButton:SetScript("OnClick", function()
		local group = addon.CreateCustomCategoryGroup and addon.CreateCustomCategoryGroup()
		if group then
			setSelectedGroupEntry(group.id)
		end
		requestCategoryRefresh()
	end)
	page.AddGroupButton = addGroupButton

	local addCategoryButton = CreateFrame("Button", nil, listCard, "UIPanelButtonTemplate")
	addCategoryButton:SetSize(96, 22)
	addCategoryButton:SetPoint("BOTTOMRIGHT", listCard, "BOTTOMRIGHT", -14, 14)
	addCategoryButton:SetText(L["settingsCategoryAddCategory"] or "Add category")
	addCategoryButton:SetScript("OnClick", function()
		local selection = getCategoryPageSelection()
		local parentGroupID = nil
		if selection.selectedType == "group" and selection.selectedGroup then
			parentGroupID = selection.selectedGroup.id
		elseif selection.selectedCategory and selection.selectedCategory.groupID then
			parentGroupID = selection.selectedCategory.groupID
		end

		local category = addon.CreateCustomCategory and addon.CreateCustomCategory(parentGroupID)
		if category then
			setSelectedCategoryEntry(category.id)
		end
		requestCategoryRefresh()
	end)
	page.AddCategoryButton = addCategoryButton

	local detailPanel = CreateFrame("Frame", nil, page)
	detailPanel:SetPoint("TOPLEFT", listCard, "TOPRIGHT", 14, 0)
	detailPanel:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -6, 0)
	page.DetailPanel = detailPanel

	local detailScrollFrame, detailContent = createScrollContainer(detailPanel, SETTINGS_DETAIL_SCROLLFRAME_NAME)
	detailScrollFrame:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 0, 0)
	detailScrollFrame:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -28, 0)
	page.DetailScrollFrame = detailScrollFrame
	page.DetailContent = detailContent

	local emptyDetailText = detailContent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	emptyDetailText:SetPoint("TOPLEFT", detailContent, "TOPLEFT", 12, -12)
	emptyDetailText:SetPoint("BOTTOMRIGHT", detailContent, "BOTTOMRIGHT", -12, 12)
	emptyDetailText:SetJustifyH("CENTER")
	emptyDetailText:SetJustifyV("MIDDLE")
	emptyDetailText:SetText(L["settingsCategoriesEmptyState"] or "Create a group or category to start building your Advanced layout.")
	page.EmptyDetailText = emptyDetailText

	local nameLabel = detailContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	nameLabel:SetPoint("TOPLEFT", detailContent, "TOPLEFT", 0, -4)
	nameLabel:SetText(NAME or "Name")
	page.NameLabel = nameLabel

	local nameBox = CreateFrame("EditBox", nil, detailContent, "InputBoxTemplate")
	nameBox:SetSize(200, 24)
	nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -8)
	nameBox:SetAutoFocus(false)
	nameBox:SetMaxLetters(40)
	nameBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	nameBox:SetScript("OnEditFocusLost", function(self)
		local selection = getCategoryPageSelection()
		if selection.selectedType == "group" and selection.selectedGroup then
			if addon.SetCustomCategoryGroupName and addon.SetCustomCategoryGroupName(selection.selectedGroup.id, self:GetText()) then
				requestCategoryRefresh()
			else
				addon.RefreshSettingsFrame()
			end
			return
		end

		local category = selection.selectedCategory
		if not category then
			return
		end

		if addon.SetCustomCategoryName and addon.SetCustomCategoryName(category.id, self:GetText()) then
			requestCategoryRefresh()
		else
			addon.RefreshSettingsFrame()
		end
	end)
	page.NameBox = nameBox

	local deleteButton = CreateFrame("Button", nil, detailContent, "UIPanelButtonTemplate")
	deleteButton:SetSize(82, 22)
	deleteButton:SetPoint("TOPRIGHT", detailContent, "TOPRIGHT", 0, -29)
	deleteButton:SetText(DELETE)
	deleteButton:SetScript("OnClick", function()
		local selection = getCategoryPageSelection()
		if selection.selectedType == "group" and selection.selectedGroup then
			if addon.RemoveCustomCategoryGroup then
				addon.RemoveCustomCategoryGroup(selection.selectedGroup.id)
			end
			settingsState.selectedGroupID = nil
			settingsState.selectedCategoryID = nil
			requestCategoryRefresh()
			return
		end

		if selection.selectedCategory and addon.RemoveCustomCategory then
			addon.RemoveCustomCategory(selection.selectedCategory.id)
			settingsState.selectedCategoryID = nil
			settingsState.selectedGroupID = nil
			requestCategoryRefresh()
		end
	end)
	page.DeleteCategoryButton = deleteButton
	nameBox:SetPoint("RIGHT", deleteButton, "LEFT", -10, 0)

	local groupLabel = detailContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	groupLabel:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, -16)
	groupLabel:SetText(L["settingsCategoryParentGroupLabel"] or "Parent group")
	page.GroupLabel = groupLabel

	local groupButton = CreateFrame("Button", nil, detailContent, "UIPanelButtonTemplate")
	groupButton:SetHeight(22)
	groupButton:SetPoint("TOPLEFT", groupLabel, "BOTTOMLEFT", 0, -8)
	groupButton:SetPoint("RIGHT", nameBox, "RIGHT", 0, 0)
	groupButton:SetScript("OnClick", function(self)
		local selection = getCategoryPageSelection()
		local category = selection.selectedCategory
		if not category then
			return
		end

		openContextMenu(self, function(_, rootDescription)
			rootDescription:CreateButton(L["settingsCategoryParentGroupNone"] or "No group", function()
				if addon.SetCustomCategoryParentGroup then
					addon.SetCustomCategoryParentGroup(category.id, nil)
				end
				requestCategoryRefresh()
			end)

			for _, group in ipairs(getCustomCategoryGroups()) do
				rootDescription:CreateButton(group.name or group.id, function(data)
					if addon.SetCustomCategoryParentGroup then
						addon.SetCustomCategoryParentGroup(category.id, data)
					end
					requestCategoryRefresh()
				end, group.id)
			end
		end)
	end)
	page.GroupButton = groupButton

	local groupHint = detailContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	groupHint:SetPoint("TOPLEFT", groupButton, "BOTTOMLEFT", 0, -6)
	groupHint:SetPoint("RIGHT", nameBox, "RIGHT", 0, 0)
	groupHint:SetJustifyH("LEFT")
	groupHint:SetJustifyV("TOP")
	groupHint:SetText(L["settingsCategoryGroupHint"] or "Categories inside the same parent group render under one shared header and collapse together in the bag and bank views.")
	page.GroupHint = groupHint

	local hideInBags = createInlineCheckbox(
		detailContent,
		L["settingsCategoryHideInBags"] or "Hide this category in bags",
		L["settingsCategoryHideInBagsTooltip"] or "Completely hides this category or group and its matching items from the bag and bank views.",
		function(value)
			local selection = getCategoryPageSelection()
			if selection.selectedType == "group" and selection.selectedGroup and addon.SetCustomCategoryGroupHidden then
				addon.SetCustomCategoryGroupHidden(selection.selectedGroup.id, value)
				requestCategoryRefresh()
			elseif selection.selectedCategory and addon.SetCustomCategoryHidden then
				addon.SetCustomCategoryHidden(selection.selectedCategory.id, value)
				requestCategoryRefresh()
			end
		end
	)
	hideInBags:SetPoint("TOPLEFT", groupHint, "BOTTOMLEFT", -4, -12)
	if hideInBags.Label then
		hideInBags.Label:SetPoint("RIGHT", detailContent, "RIGHT", -14, 0)
	end
	page.HideInBags = hideInBags

	local desaturateItems = createInlineCheckbox(
		detailContent,
		L["settingsCategoryDesaturateItems"] or "Desaturate items in this category or group",
		L["settingsCategoryDesaturateItemsTooltip"] or "Shows matching item icons in grayscale in bag and bank views.",
		function(value)
			local selection = getCategoryPageSelection()
			if selection.selectedType == "group" and selection.selectedGroup and addon.SetCustomCategoryGroupDesaturateItems then
				addon.SetCustomCategoryGroupDesaturateItems(selection.selectedGroup.id, value)
				requestCategoryRefresh()
			elseif selection.selectedCategory and addon.SetCustomCategoryDesaturateItems then
				addon.SetCustomCategoryDesaturateItems(selection.selectedCategory.id, value)
				requestCategoryRefresh()
			end
		end
	)
	desaturateItems:SetPoint("TOPLEFT", hideInBags, "BOTTOMLEFT", 0, -8)
	if desaturateItems.Label then
		desaturateItems.Label:SetPoint("RIGHT", detailContent, "RIGHT", -14, 0)
	end
	page.DesaturateItems = desaturateItems

	local priorityLabel = detailContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	priorityLabel:SetPoint("TOPLEFT", desaturateItems, "BOTTOMLEFT", 4, -16)
	priorityLabel:SetText(L["settingsCategoryPriorityLabel"] or "Priority")
	page.PriorityLabel = priorityLabel

	local priorityValue = CreateFrame("EditBox", nil, detailContent, "InputBoxTemplate")
	priorityValue:SetPoint("LEFT", priorityLabel, "RIGHT", 12, 0)
	priorityValue:SetSize(46, 20)
	priorityValue:SetJustifyH("CENTER")
	priorityValue:SetAutoFocus(false)
	priorityValue:SetNumeric(true)
	priorityValue:SetMaxLetters(3)
	priorityValue:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	priorityValue:SetScript("OnEditFocusLost", function(self)
		local selection = getCategoryPageSelection()
		local value = tonumber(self:GetText())
		if selection.selectedType == "group" and selection.selectedGroup then
			if value and addon.SetCustomCategoryGroupSortOrder and addon.SetCustomCategoryGroupSortOrder(selection.selectedGroup.id, value) then
				requestCategoryRefresh()
			else
				addon.RefreshSettingsFrame("categories")
			end
			return
		end

		if selection.selectedCategory and value and addon.SetCustomCategorySortOrder and addon.SetCustomCategorySortOrder(selection.selectedCategory.id, value) then
			requestCategoryRefresh()
		else
			addon.RefreshSettingsFrame("categories")
		end
	end)
	page.PriorityValue = priorityValue

	local priorityDownButton = CreateFrame("Button", nil, detailContent, "UIPanelButtonTemplate")
	priorityDownButton:SetSize(24, 20)
	priorityDownButton:SetPoint("LEFT", priorityValue, "RIGHT", 4, 0)
	priorityDownButton:SetText("-")
	priorityDownButton:SetScript("OnClick", function()
		local selection = getCategoryPageSelection()
		if selection.selectedType == "group" and selection.selectedGroup and addon.SetCustomCategoryGroupSortOrder then
			addon.SetCustomCategoryGroupSortOrder(selection.selectedGroup.id, (selection.selectedGroup.sortOrder or 0) - 1)
			requestCategoryRefresh()
			return
		end

		local category = selection.selectedCategory
		if not category or not addon.SetCustomCategorySortOrder then
			return
		end
		addon.SetCustomCategorySortOrder(category.id, (category.sortOrder or 0) - 1)
		requestCategoryRefresh()
	end)
	page.PriorityDownButton = priorityDownButton

	local priorityUpButton = CreateFrame("Button", nil, detailContent, "UIPanelButtonTemplate")
	priorityUpButton:SetSize(24, 20)
	priorityUpButton:SetPoint("LEFT", priorityDownButton, "RIGHT", 4, 0)
	priorityUpButton:SetText("+")
	priorityUpButton:SetScript("OnClick", function()
		local selection = getCategoryPageSelection()
		if selection.selectedType == "group" and selection.selectedGroup and addon.SetCustomCategoryGroupSortOrder then
			addon.SetCustomCategoryGroupSortOrder(selection.selectedGroup.id, (selection.selectedGroup.sortOrder or 0) + 1)
			requestCategoryRefresh()
			return
		end

		local category = selection.selectedCategory
		if not category or not addon.SetCustomCategorySortOrder then
			return
		end
		addon.SetCustomCategorySortOrder(category.id, (category.sortOrder or 0) + 1)
		requestCategoryRefresh()
	end)
	page.PriorityUpButton = priorityUpButton

	local categoryColorLabel = detailContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	categoryColorLabel:SetPoint("LEFT", priorityUpButton, "RIGHT", 20, 0)
	categoryColorLabel:SetText(L["settingsCategoryColorLabel"] or "Color")
	page.CategoryColorLabel = categoryColorLabel

	local categoryColorSwatch = CreateFrame("Button", nil, detailContent, "ColorSwatchTemplate")
	categoryColorSwatch:SetSize(18, 18)
	categoryColorSwatch:SetPoint("LEFT", categoryColorLabel, "RIGHT", 8, 0)
	categoryColorSwatch:SetScript("OnClick", function()
		local selection = getCategoryPageSelection()
		local colorTarget = selection.selectedCategory or selection.selectedGroup
		if not colorTarget then
			return
		end

		openColorPicker(colorTarget.color, function(r, g, b)
			if selection.selectedType == "group" then
				if addon.SetCustomCategoryGroupColor then
					addon.SetCustomCategoryGroupColor(colorTarget.id, { r, g, b })
				end
			elseif addon.SetCustomCategoryColor then
				addon.SetCustomCategoryColor(colorTarget.id, { r, g, b })
			end
			requestCategoryRefresh()
		end)
	end)
	categoryColorSwatch:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["settingsCategoryColorLabel"] or "Color", 1, 0.82, 0)
		GameTooltip:AddLine(L["settingsCategoryColorTooltip"] or "Choose the color used for this custom group in the list and bag sections.", nil, nil, nil, true)
		GameTooltip:Show()
	end)
	categoryColorSwatch:HookScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	page.CategoryColorSwatch = categoryColorSwatch

	local priorityHint = detailContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	priorityHint:SetPoint("TOPLEFT", priorityLabel, "BOTTOMLEFT", 0, -6)
	priorityHint:SetPoint("RIGHT", detailContent, "RIGHT", -14, 0)
	priorityHint:SetJustifyH("LEFT")
	priorityHint:SetJustifyV("TOP")
	priorityHint:SetText(L["settingsCategoryPriorityHint"] or "Higher priority wins when one item matches multiple categories.")
	page.PriorityHint = priorityHint

	local groupSpacerBefore = createInlineCheckbox(
		detailContent,
		L["settingsCategoryGroupSpacerBefore"] or "Add spacer before group",
		L["settingsCategoryGroupSpacerBeforeTooltip"] or "",
		function(value)
			local selection = getCategoryPageSelection()
			if selection.selectedType == "group" and selection.selectedGroup and addon.SetCustomCategoryGroupSpacerBefore then
				addon.SetCustomCategoryGroupSpacerBefore(selection.selectedGroup.id, value)
				requestCategoryRefresh()
			end
		end
	)
	groupSpacerBefore:SetPoint("TOPLEFT", priorityHint, "BOTTOMLEFT", -4, -14)
	if groupSpacerBefore.Label then
		groupSpacerBefore.Label:SetPoint("RIGHT", detailContent, "RIGHT", -14, 0)
	end
	page.GroupSpacerBefore = groupSpacerBefore

	local groupCombineSubcategories = createInlineCheckbox(
		detailContent,
		L["settingsCategoryGroupCombineSubcategories"] or "Combine subcategories in this group",
		L["settingsCategoryGroupCombineSubcategoriesTooltip"] or "",
		function(value)
			local selection = getCategoryPageSelection()
			if selection.selectedType == "group" and selection.selectedGroup and addon.SetCustomCategoryGroupCombineSubcategories then
				addon.SetCustomCategoryGroupCombineSubcategories(selection.selectedGroup.id, value)
				requestCategoryRefresh()
			end
		end
	)
	groupCombineSubcategories:SetPoint("TOPLEFT", groupSpacerBefore, "BOTTOMLEFT", 0, -8)
	if groupCombineSubcategories.Label then
		groupCombineSubcategories.Label:SetPoint("RIGHT", detailContent, "RIGHT", -14, 0)
	end
	page.GroupCombineSubcategories = groupCombineSubcategories

	local matchPriorityLabel = detailContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	matchPriorityLabel:SetPoint("TOPLEFT", priorityHint, "BOTTOMLEFT", 0, -16)
	matchPriorityLabel:SetText(L["settingsCategoryPriorityLabel"] or "Priority")
	page.MatchPriorityLabel = matchPriorityLabel

	local matchPriorityValue = CreateFrame("EditBox", nil, detailContent, "InputBoxTemplate")
	matchPriorityValue:SetPoint("LEFT", matchPriorityLabel, "RIGHT", 12, 0)
	matchPriorityValue:SetSize(46, 20)
	matchPriorityValue:SetJustifyH("CENTER")
	matchPriorityValue:SetAutoFocus(false)
	matchPriorityValue:SetNumeric(true)
	matchPriorityValue:SetMaxLetters(3)
	matchPriorityValue:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	matchPriorityValue:SetScript("OnEditFocusLost", function(self)
		local _, category = getSelectedCustomCategoryState()
		local value = tonumber(self:GetText())
		if category and value and addon.SetCustomCategoryPriority and addon.SetCustomCategoryPriority(category.id, value) then
			requestCategoryRefresh()
		else
			addon.RefreshSettingsFrame("categories")
		end
	end)
	page.MatchPriorityValue = matchPriorityValue

	local matchPriorityDownButton = CreateFrame("Button", nil, detailContent, "UIPanelButtonTemplate")
	matchPriorityDownButton:SetSize(24, 20)
	matchPriorityDownButton:SetPoint("LEFT", matchPriorityValue, "RIGHT", 4, 0)
	matchPriorityDownButton:SetText("-")
	matchPriorityDownButton:SetScript("OnClick", function()
		local _, category = getSelectedCustomCategoryState()
		if not category or not addon.SetCustomCategoryPriority then
			return
		end
		addon.SetCustomCategoryPriority(category.id, (category.priority or 0) - 1)
		requestCategoryRefresh()
	end)
	page.MatchPriorityDownButton = matchPriorityDownButton

	local matchPriorityUpButton = CreateFrame("Button", nil, detailContent, "UIPanelButtonTemplate")
	matchPriorityUpButton:SetSize(24, 20)
	matchPriorityUpButton:SetPoint("LEFT", matchPriorityDownButton, "RIGHT", 4, 0)
	matchPriorityUpButton:SetText("+")
	matchPriorityUpButton:SetScript("OnClick", function()
		local _, category = getSelectedCustomCategoryState()
		if not category or not addon.SetCustomCategoryPriority then
			return
		end
		addon.SetCustomCategoryPriority(category.id, (category.priority or 0) + 1)
		requestCategoryRefresh()
	end)
	page.MatchPriorityUpButton = matchPriorityUpButton

	local matchPriorityHint = detailContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	matchPriorityHint:SetPoint("TOPLEFT", matchPriorityLabel, "BOTTOMLEFT", 0, -6)
	matchPriorityHint:SetPoint("RIGHT", detailContent, "RIGHT", -14, 0)
	matchPriorityHint:SetJustifyH("LEFT")
	matchPriorityHint:SetJustifyV("TOP")
	matchPriorityHint:SetText(L["settingsCategoryPriorityHint"] or "Higher priority wins when one item matches multiple categories.")
	page.MatchPriorityHint = matchPriorityHint

	local sortLabel = detailContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	sortLabel:SetPoint("TOPLEFT", matchPriorityHint, "BOTTOMLEFT", 0, -16)
	sortLabel:SetText(L["settingsCategorySortLabel"] or "Sort")
	page.SortLabel = sortLabel

	local sortButton = CreateFrame("Button", nil, detailContent, "UIPanelButtonTemplate")
	sortButton:SetHeight(22)
	sortButton:SetPoint("TOPLEFT", sortLabel, "BOTTOMLEFT", 0, -8)
	sortButton:SetPoint("RIGHT", nameBox, "RIGHT", 0, 0)
	sortButton:SetScript("OnClick", function(self)
		local _, category = getSelectedCustomCategoryState()
		if not category then
			return
		end

		local options = addon.GetCategorySortModeOptions and addon.GetCategorySortModeOptions() or {}
		openSimpleRadioMenu(self, options, category.sortMode or "default", function(value)
			if addon.SetCustomCategorySortMode then
				addon.SetCustomCategorySortMode(category.id, value)
			end
			requestCategoryRefresh()
		end)
	end)
	page.SortButton = sortButton

	local sortHint = detailContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	sortHint:SetPoint("TOPLEFT", sortButton, "BOTTOMLEFT", 0, -6)
	sortHint:SetPoint("RIGHT", detailContent, "RIGHT", -14, 0)
	sortHint:SetJustifyH("LEFT")
	sortHint:SetJustifyV("TOP")
	sortHint:SetText(L["settingsCategorySortHint"] or "Controls how items are ordered inside this category.")
	page.SortHint = sortHint

	local itemsCard = CreateFrame("Frame", nil, detailContent, "BackdropTemplate")
	itemsCard:SetPoint("TOPLEFT", sortHint, "BOTTOMLEFT", 0, -16)
	itemsCard:SetPoint("RIGHT", detailContent, "RIGHT", 0, 0)
	itemsCard:SetHeight(140)
	createCardBackdrop(itemsCard)
	page.ItemsCard = itemsCard

	local itemsTitle = itemsCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	itemsTitle:SetPoint("TOPLEFT", itemsCard, "TOPLEFT", 14, -14)
	itemsTitle:SetText(L["settingsCategoryAssignedItemsTitle"] or "Assigned items")
	page.ItemsTitle = itemsTitle

	local itemsHint = itemsCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	itemsHint:SetPoint("TOPLEFT", itemsTitle, "BOTTOMLEFT", 0, -4)
	itemsHint:SetPoint("RIGHT", itemsCard, "RIGHT", -14, 0)
	itemsHint:SetJustifyH("LEFT")
	itemsHint:SetJustifyV("TOP")
	itemsHint:SetText(L["settingsCategoryAssignedItemsHint"] or "Paste an item link or ID, or drop an item here to pin it to this category.")
	page.ItemsHint = itemsHint

	local dropTarget = CreateFrame("Button", nil, itemsCard, "BackdropTemplate")
	dropTarget:SetSize(34, 34)
	dropTarget:SetPoint("TOPLEFT", itemsCard, "TOPLEFT", 14, -54)
	dropTarget:RegisterForClicks("LeftButtonUp")
	createCardBackdrop(dropTarget)
	page.DropTarget = dropTarget

	local dropBackground = dropTarget:CreateTexture(nil, "BACKGROUND")
	dropBackground:SetAllPoints()
	dropBackground:SetAtlas("bags-item-slot64", true)
	dropTarget.Background = dropBackground

	local dropPlus = dropTarget:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	dropPlus:SetPoint("CENTER")
	dropPlus:SetText("+")
	dropTarget.Plus = dropPlus

	dropTarget:SetScript("OnMouseUp", function()
		local _, category = getSelectedCustomCategoryState()
		if category and tryAddCursorItemToCategory(category.id) then
			requestCategoryRefresh()
		end
	end)
	dropTarget:SetScript("OnReceiveDrag", function()
		local _, category = getSelectedCustomCategoryState()
		if category and tryAddCursorItemToCategory(category.id) then
			requestCategoryRefresh()
		end
	end)
	dropTarget:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["settingsCategoryAssignedItemsTitle"] or "Assigned items", 1, 0.82, 0)
		GameTooltip:AddLine(L["settingsCategoryDropItemHint"] or "Drop an item here to assign it directly.", nil, nil, nil, true)
		GameTooltip:Show()
	end)
	dropTarget:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local itemInput = CreateFrame("EditBox", nil, itemsCard, "InputBoxTemplate")
	itemInput:SetSize(146, 24)
	itemInput:SetPoint("LEFT", dropTarget, "RIGHT", 10, 0)
	itemInput:SetAutoFocus(false)
	itemInput:SetMaxLetters(128)
	itemInput:SetScript("OnEnterPressed", function(self)
		local _, category = getSelectedCustomCategoryState()
		if not category then
			self:ClearFocus()
			return
		end

		if addon.AddCustomCategoryItemID and addon.AddCustomCategoryItemID(category.id, self:GetText()) then
			self:SetText("")
			requestCategoryRefresh()
		else
			self:ClearFocus()
			addon.RefreshSettingsFrame()
		end
	end)
	attachEditBoxPlaceholder(itemInput, L["settingsCategoryItemPlaceholder"] or "Item link or ID")
	page.ItemInput = itemInput

	local addItemButton = CreateFrame("Button", nil, itemsCard, "UIPanelButtonTemplate")
	addItemButton:SetSize(62, 22)
	addItemButton:SetPoint("LEFT", itemInput, "RIGHT", 8, 0)
	addItemButton:SetText(ADD)
	addItemButton:SetScript("OnClick", function()
		local _, category = getSelectedCustomCategoryState()
		if not category then
			return
		end

		if addon.AddCustomCategoryItemID and addon.AddCustomCategoryItemID(category.id, itemInput:GetText()) then
			itemInput:SetText("")
			requestCategoryRefresh()
		else
			addon.RefreshSettingsFrame()
		end
	end)
	page.AddItemButton = addItemButton

	local itemsListScrollFrame, itemsListContent = createScrollContainer(itemsCard, SETTINGS_ASSIGNED_ITEMS_SCROLLFRAME_NAME, {
		scrollbarInside = true,
		contentPaddingRight = 12,
	})
	itemsListScrollFrame:SetPoint("TOPLEFT", dropTarget, "BOTTOMLEFT", 0, -10)
	itemsListScrollFrame:SetPoint("BOTTOMRIGHT", itemsCard, "BOTTOMRIGHT", -14, 12)
	page.ItemsListScrollFrame = itemsListScrollFrame
	page.ItemsListContent = itemsListContent
	page.ItemsList = itemsListContent

	local noItemsText = itemsListContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	noItemsText:SetPoint("TOPLEFT", itemsListContent, "TOPLEFT", 0, 0)
	noItemsText:SetPoint("BOTTOMRIGHT", itemsListContent, "BOTTOMRIGHT", 0, 0)
	noItemsText:SetJustifyH("LEFT")
	noItemsText:SetJustifyV("MIDDLE")
	noItemsText:SetText(L["settingsCategoryNoItems"] or "No items assigned yet.")
	page.NoItemsText = noItemsText

	local rulesCard = CreateFrame("Frame", nil, detailContent, "BackdropTemplate")
	rulesCard:SetPoint("TOPLEFT", itemsCard, "BOTTOMLEFT", 0, -12)
	rulesCard:SetPoint("RIGHT", detailContent, "RIGHT", 0, 0)
	rulesCard:SetHeight(180)
	createCardBackdrop(rulesCard)
	page.RulesCard = rulesCard

	local rulesTitle = rulesCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	rulesTitle:SetPoint("TOPLEFT", rulesCard, "TOPLEFT", 14, -14)
	rulesTitle:SetText(L["settingsCategoryAutomaticRulesTitle"] or "Automatic rules")
	page.RulesTitle = rulesTitle

	local rulesHint = rulesCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	rulesHint:SetPoint("TOPLEFT", rulesTitle, "BOTTOMLEFT", 0, -4)
	rulesHint:SetPoint("RIGHT", rulesCard, "RIGHT", -14, 0)
	rulesHint:SetJustifyH("LEFT")
	rulesHint:SetJustifyV("TOP")
	rulesHint:SetText(L["settingsCategoryAutomaticRulesHint"] or "Add base conditions now, then expand later with nested AND / OR groups.")
	page.RulesHint = rulesHint

	local rulesContent = CreateFrame("Frame", nil, rulesCard)
	rulesContent:SetPoint("TOPLEFT", rulesHint, "BOTTOMLEFT", 0, -10)
	rulesContent:SetPoint("BOTTOMRIGHT", rulesCard, "BOTTOMRIGHT", -14, 12)
	page.RulesContent = rulesContent

	return page
end

refreshCategoriesPage = function(page)
	if not page then
		return
	end

	if page.BuiltInCard then
		page.BuiltInCard:Hide()
	end
	for index = 1, #page.BuiltInCategoryButtons do
		page.BuiltInCategoryButtons[index]:Hide()
	end

	local selection = getCategoryPageSelection()
	local groups = selection.groups or {}
	local categories = selection.categories or {}
	local selectedCategory = selection.selectedCategory
	local selectedGroup = selection.selectedGroup
	local selectedType = selection.selectedType
	local listEntries = buildCustomCategoryListEntries(groups, categories)
	local listOffset = 0

	for index, entry in ipairs(listEntries) do
		local button = acquireCategoryListButton(page, index)
		button.entryType = entry.type
		button.entryID = entry.id
		button:SetHeight(entry.type == "group" and 36 or 30)
		button.Name:SetText(entry.name)
		button.Priority:SetText(
			entry.type == "group"
				and string.format("O%d", entry.sortOrder or 0)
				or string.format("O%d", entry.sortOrder or 0)
		)
		local indentOffset = (entry.indent or 0) * CATEGORY_LIST_CHILD_INDENT
		button.ColorBar:ClearAllPoints()
		button.ColorBar:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
		button.ColorBar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
		button.Indent:ClearAllPoints()
		button.Indent:SetPoint("LEFT", button.ColorBar, "RIGHT", 6, 0)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", page.ListContent, "TOPLEFT", indentOffset, -listOffset)
		button:SetPoint("RIGHT", page.ListContent, "RIGHT", 0, 0)
		setCategoryButtonVisual(
			button,
			(entry.type == "group" and selectedType == "group" and selectedGroup and selectedGroup.id == entry.id)
				or (entry.type == "category" and selectedType == "category" and selectedCategory and selectedCategory.id == entry.id),
			entry.color,
			entry.type,
			entry.hidden == true
		)
		button:Show()
		listOffset = listOffset + button:GetHeight() + 6
	end

	for index = #listEntries + 1, #page.CategoryButtons do
		page.CategoryButtons[index]:Hide()
	end

	page.EmptyListText:SetShown(#listEntries == 0)
	updateScrollContainer(page.ListScrollFrame, page.ListContent, math.max(4, listOffset))

	local hasSelection = selectedType ~= nil
	local isCategorySelection = selectedType == "category" and selectedCategory ~= nil
	local isGroupSelection = selectedType == "group" and selectedGroup ~= nil
	page.EmptyDetailText:SetShown(not hasSelection)
	page.NameLabel:SetShown(hasSelection)
	page.NameBox:SetShown(hasSelection)
	page.DeleteCategoryButton:SetShown(hasSelection)
	page.GroupLabel:SetShown(isCategorySelection)
	page.GroupButton:SetShown(isCategorySelection)
	page.GroupHint:SetShown(isCategorySelection)
	page.PriorityLabel:SetShown(hasSelection)
	page.PriorityValue:SetShown(hasSelection)
	page.PriorityDownButton:SetShown(hasSelection)
	page.PriorityUpButton:SetShown(hasSelection)
	page.MatchPriorityLabel:SetShown(isCategorySelection)
	page.MatchPriorityValue:SetShown(isCategorySelection)
	page.MatchPriorityDownButton:SetShown(isCategorySelection)
	page.MatchPriorityUpButton:SetShown(isCategorySelection)
	page.MatchPriorityHint:SetShown(isCategorySelection)
	page.SortLabel:SetShown(isCategorySelection)
	page.SortButton:SetShown(isCategorySelection)
	page.SortHint:SetShown(isCategorySelection)
	page.CategoryColorLabel:SetShown(hasSelection)
	page.CategoryColorSwatch:SetShown(hasSelection)
	page.HideInBags:SetShown(hasSelection)
	if page.HideInBags.Label then
		page.HideInBags.Label:SetShown(hasSelection)
	end
	page.DesaturateItems:SetShown(hasSelection)
	if page.DesaturateItems.Label then
		page.DesaturateItems.Label:SetShown(hasSelection)
	end
	page.PriorityHint:SetShown(hasSelection)
	page.GroupSpacerBefore:SetShown(isGroupSelection)
	if page.GroupSpacerBefore.Label then
		page.GroupSpacerBefore.Label:SetShown(isGroupSelection)
	end
	page.GroupCombineSubcategories:SetShown(isGroupSelection)
	if page.GroupCombineSubcategories.Label then
		page.GroupCombineSubcategories.Label:SetShown(isGroupSelection)
	end
	page.ItemsCard:SetShown(isCategorySelection)
	page.RulesCard:SetShown(isCategorySelection)

	if not hasSelection then
		for index = 1, #page.AssignedItemRows do
			page.AssignedItemRows[index]:Hide()
		end
		for index = 1, #page.RuleNodeFrames do
			page.RuleNodeFrames[index]:Hide()
		end
		updateScrollContainer(page.DetailScrollFrame, page.DetailContent, page.DetailScrollFrame:GetHeight())
		return
	end

	if not page.NameBox:HasFocus() then
		page.NameBox:SetText((selectedCategory and selectedCategory.name) or (selectedGroup and selectedGroup.name) or "")
	end
	if page.CategoryColorSwatch then
		local colorOwner = selectedCategory or selectedGroup or {}
		local color = colorOwner.color or { 1, 1, 1 }
		page.CategoryColorSwatch:SetColorRGB(color[1] or 1, color[2] or 1, color[3] or 1)
	end
	if page.HideInBags then
		page.HideInBags:SetChecked((selectedCategory and selectedCategory.hidden == true) or (selectedGroup and selectedGroup.hidden == true) or false)
	end
	if page.DesaturateItems then
		page.DesaturateItems:SetChecked((selectedCategory and selectedCategory.desaturateItems == true) or (selectedGroup and selectedGroup.desaturateItems == true) or false)
	end

	if isGroupSelection then
		page.PriorityLabel:ClearAllPoints()
		page.PriorityLabel:SetPoint("TOPLEFT", page.DesaturateItems, "BOTTOMLEFT", 4, -16)
		page.PriorityLabel:SetText(L["settingsCategoryOrderLabel"] or "Display order")
		page.CategoryColorLabel:ClearAllPoints()
		page.CategoryColorLabel:SetPoint("LEFT", page.PriorityUpButton, "RIGHT", 20, 0)
		page.CategoryColorSwatch:ClearAllPoints()
		page.CategoryColorSwatch:SetPoint("LEFT", page.CategoryColorLabel, "RIGHT", 8, 0)
		page.PriorityHint:ClearAllPoints()
		page.PriorityHint:SetPoint("TOPLEFT", page.PriorityLabel, "BOTTOMLEFT", 0, -6)
		page.PriorityHint:SetPoint("RIGHT", page.DetailContent, "RIGHT", -14, 0)
		page.PriorityHint:SetText(L["settingsCategoryOrderHint"] or "Lower values render earlier. This only changes where the entry appears, not which items match its rules.")
		page.SortButton:SetText(L["settingsCategorySortDefault"] or "Default")
		page.GroupSpacerBefore:SetChecked(selectedGroup.spacerBefore == true)
		page.GroupCombineSubcategories:SetChecked(selectedGroup.combineSubcategories == true)
		if not page.PriorityValue:HasFocus() then
			page.PriorityValue:SetText(tostring(selectedGroup.sortOrder or 0))
		end
		page.PriorityDownButton:SetEnabled((selectedGroup.sortOrder or 0) > 0)
		page.PriorityUpButton:SetEnabled((selectedGroup.sortOrder or 0) < 999)

		for index = 1, #page.AssignedItemRows do
			page.AssignedItemRows[index]:Hide()
		end
		for index = 1, #page.RuleNodeFrames do
			page.RuleNodeFrames[index]:Hide()
		end

		local detailTop = page.DetailContent:GetTop()
		local groupSpacerBottom = page.GroupCombineSubcategories:GetBottom()
		local contentHeight
		if detailTop and groupSpacerBottom then
			contentHeight = math.ceil((detailTop - groupSpacerBottom) + 24)
		else
			contentHeight = 184
		end
		updateScrollContainer(page.DetailScrollFrame, page.DetailContent, contentHeight)
		return
	end

	page.PriorityLabel:ClearAllPoints()
	page.PriorityLabel:SetPoint("TOPLEFT", page.DesaturateItems, "BOTTOMLEFT", 4, -16)
	page.PriorityLabel:SetText(L["settingsCategoryOrderLabel"] or "Display order")
	page.CategoryColorLabel:ClearAllPoints()
	page.CategoryColorLabel:SetPoint("LEFT", page.PriorityUpButton, "RIGHT", 20, 0)
	page.CategoryColorSwatch:ClearAllPoints()
	page.CategoryColorSwatch:SetPoint("LEFT", page.CategoryColorLabel, "RIGHT", 8, 0)
	page.PriorityHint:ClearAllPoints()
	page.PriorityHint:SetPoint("TOPLEFT", page.PriorityLabel, "BOTTOMLEFT", 0, -6)
	page.PriorityHint:SetPoint("RIGHT", page.DetailContent, "RIGHT", -14, 0)
	page.PriorityHint:SetText(L["settingsCategoryOrderHint"] or "Lower values render earlier. This only changes where the entry appears, not which items match its rules.")

	local sortLabelText = L["settingsCategorySortDefault"] or "Default"
	for _, option in ipairs(addon.GetCategorySortModeOptions and addon.GetCategorySortModeOptions() or {}) do
		if option.value == (selectedCategory.sortMode or "default") then
			sortLabelText = option.label or sortLabelText
			break
		end
	end
	page.SortButton:SetText(sortLabelText)

	local parentGroupName = L["settingsCategoryParentGroupNone"] or "No group"
	if selectedCategory and selectedCategory.groupID then
		for _, group in ipairs(groups) do
			if group.id == selectedCategory.groupID then
				parentGroupName = group.name or parentGroupName
				break
			end
		end
	end
	page.GroupButton:SetText(parentGroupName)
	if not page.PriorityValue:HasFocus() then
		page.PriorityValue:SetText(tostring(selectedCategory.sortOrder or 0))
	end
	page.PriorityDownButton:SetEnabled((selectedCategory.sortOrder or 0) > 0)
	page.PriorityUpButton:SetEnabled((selectedCategory.sortOrder or 0) < 999)
	if not page.MatchPriorityValue:HasFocus() then
		page.MatchPriorityValue:SetText(tostring(selectedCategory.priority or 0))
	end
	page.MatchPriorityDownButton:SetEnabled((selectedCategory.priority or 0) > 0)
	page.MatchPriorityUpButton:SetEnabled((selectedCategory.priority or 0) < 100)

	if not page.ItemInput:HasFocus() then
		page.ItemInput:SetText("")
	end

	local itemIDs = selectedCategory.itemIDs or {}
	for index, itemID in ipairs(itemIDs) do
		local row = acquireAssignedItemRow(page, index)
		local itemInfo = getCategoryItemDisplayInfo(itemID)
		row.itemID = itemID
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", page.ItemsList, "TOPLEFT", 0, -((index - 1) * 28))
		row:SetPoint("RIGHT", page.ItemsList, "RIGHT", 0, 0)
		row.Icon:SetTexture(itemInfo.iconFileID or "Interface\\Icons\\INV_Misc_QuestionMark")
		row.Text:SetText(itemInfo.name)

		if itemInfo.quality and C_Item.GetItemQualityColor then
			local r, g, b = C_Item.GetItemQualityColor(itemInfo.quality)
			row.Text:SetTextColor(r or 1, g or 1, b or 1)
		else
			row.Text:SetTextColor(1, 1, 1)
		end

		row.RemoveButton:SetScript("OnClick", function()
			if addon.RemoveCustomCategoryItemID then
				addon.RemoveCustomCategoryItemID(selectedCategory.id, itemID)
			end
			requestCategoryRefresh()
		end)
		row:Show()
	end

	for index = #itemIDs + 1, #page.AssignedItemRows do
		page.AssignedItemRows[index]:Hide()
	end

	local visibleItemRows = math.max(1, math.min(#itemIDs, ASSIGNED_ITEMS_MAX_VISIBLE_ROWS))
	local itemsListHeight = math.max(24, visibleItemRows * ASSIGNED_ITEM_ROW_HEIGHT)
	page.NoItemsText:SetShown(#itemIDs == 0)
	page.ItemsCard:SetHeight(math.max(140, 112 + itemsListHeight))
	updateScrollContainer(page.ItemsListScrollFrame, page.ItemsListContent, math.max(24, #itemIDs * ASSIGNED_ITEM_ROW_HEIGHT))

	page.nextRuleNodeFrame = 0
	local yOffset = 0
	if selectedCategory.ruleTree then
		yOffset = layoutCategoryRuleNode(page, selectedCategory.id, selectedCategory.ruleTree, 0, yOffset)
	end

	for index = page.nextRuleNodeFrame + 1, #page.RuleNodeFrames do
		page.RuleNodeFrames[index]:Hide()
	end
	page.RulesCard:SetHeight(math.max(180, 74 + math.max(yOffset, 40)))
	local detailTop = page.DetailContent:GetTop()
	local rulesBottom = page.RulesCard:GetBottom()
	local contentHeight
	if detailTop and rulesBottom then
		contentHeight = math.ceil((detailTop - rulesBottom) + 24)
	else
		contentHeight = 156 + page.ItemsCard:GetHeight() + 12 + page.RulesCard:GetHeight()
	end
	updateScrollContainer(page.DetailScrollFrame, page.DetailContent, contentHeight)

	if page.AddGroupButton then
		page.AddGroupButton:SetText(L["settingsCategoryAddGroup"] or "Add group")
	end
	if page.AddCategoryButton then
		page.AddCategoryButton:SetText(L["settingsCategoryAddCategory"] or "Add category")
	end
end

local function createLayoutPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints()

	createPageHeader(
		page,
		L["settingsCategoryLayout"] or "Layout",
		L["settingsLayoutDescription"] or "Basic layout toggles for the bag window."
	)

	local scrollFrame, content = createScrollContainer(page, SETTINGS_LAYOUT_SCROLLFRAME_NAME)
	scrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -74)
	scrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 0)
	page.ScrollFrame = scrollFrame
	page.Content = content
	page.LayoutContentHeight = 1940

	local contentParent = content

	page.OneBagMode = createCheckbox(
		contentParent,
		L["settingsOneBagMode"] or "One Bag mode",
		L["settingsOneBagModeTooltip"] or "",
		0,
		-8,
		function(value)
			if addon.SetOneBagMode and addon.SetOneBagMode(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true, true)
			end
		end
	)

	page.ShowCategories = createCheckbox(
		contentParent,
		L["settingsShowCategories"] or "Show item categories",
		L["settingsShowCategoriesTooltip"] or "",
		0,
		-38,
		function(value)
			getSettings().showCategories = value
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	)

	page.OneBagFreeSlotsAtEnd = createCheckbox(
		contentParent,
		L["settingsOneBagFreeSlotsAtEnd"] or "Move free slots to end",
		L["settingsOneBagFreeSlotsAtEndTooltip"] or "",
		0,
		-68,
		function(value)
			if addon.SetOneBagFreeSlotsAtEnd and addon.SetOneBagFreeSlotsAtEnd(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true, true)
			end
		end
	)

	page.CombineFreeSlots = createCheckbox(
		contentParent,
		L["settingsCombineFreeSlots"] or "Combine free slots into indicators",
		L["settingsCombineFreeSlotsTooltip"] or "",
		0,
		-68,
		function(value)
			getSettings().combineFreeSlots = value
			requestBagRefresh(true)
		end
	)

	page.ShowFreeSlots = createCheckbox(
		contentParent,
		L["settingsShowFreeSlots"] or "Show free slots",
		L["settingsShowFreeSlotsTooltip"] or "",
		0,
		-98,
		function(value)
			if addon.SetShowFreeSlots and addon.SetShowFreeSlots(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end
	)

	page.CombineDuplicateItems = createCheckbox(
		contentParent,
		L["settingsCombineUnstackableItems"] or "Combine identical items",
		L["settingsCombineUnstackableItemsTooltip"] or "",
		0,
		-128,
		function(value)
			getSettings().combineUnstackableItems = value
			requestBagRefresh(true)
		end
	)

	page.ClearNewItemsOnHeaderClick = createCheckbox(
		contentParent,
		L["settingsClearNewItemsOnHeaderClick"] or "Click New Items header to clear",
		L["settingsClearNewItemsOnHeaderClickTooltip"] or "",
		0,
		-158,
		function(value)
			if addon.SetClearNewItemsOnHeaderClick and addon.SetClearNewItemsOnHeaderClick(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true, true)
			end
		end
	)

	page.CompactCategoryLayout = createCheckbox(
		contentParent,
		L["settingsCompactCategoryLayout"] or "Compact category layout",
		L["settingsCompactCategoryLayoutTooltip"] or "",
		0,
		-188,
		function(value)
			if addon.SetCompactCategoryLayout and addon.SetCompactCategoryLayout(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end
	)

	page.CategoryTreeView = createCheckbox(
		contentParent,
		L["settingsCategoryTreeView"] or "Tree view for grouped categories",
		L["settingsCategoryTreeViewTooltip"] or "",
		0,
		-218,
		function(value)
			if addon.SetCategoryTreeView and addon.SetCategoryTreeView(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true, true)
			end
		end
	)

	page.ShowCloseButton = createCheckbox(
		contentParent,
		L["settingsShowCloseButton"] or "Show close button",
		L["settingsShowCloseButtonTooltip"] or "",
		0,
		-248,
		function(value)
			if addon.SetShowCloseButton and addon.SetShowCloseButton(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true, true)
			end
		end
	)

	page.RememberLastBankTab = createCheckbox(
		contentParent,
		L["settingsRememberLastBankTab"] or "Remember last bank tab",
		L["settingsRememberLastBankTabTooltip"] or "",
		0,
		-278,
		function(value)
			if addon.SetRememberLastBankTab and addon.SetRememberLastBankTab(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true, true)
			end
		end
	)

	page.UseIntegratedBank = createCheckbox(
		contentParent,
		L["settingsUseIntegratedBank"] or "Use integrated bank",
		L["settingsUseIntegratedBankTooltip"] or "",
		0,
		-308,
		function(value)
			if addon.SetUseIntegratedBank and addon.SetUseIntegratedBank(value) then
				if value then
					if Bags.functions and Bags.functions.EnableBank then
						Bags.functions.EnableBank()
					end
				elseif Bags.functions and Bags.functions.HideBankFrame then
					Bags.functions.HideBankFrame()
				end
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true, true)
			end
		end
	)

	local compactGapRow = CreateFrame("Frame", nil, contentParent)
	compactGapRow:SetHeight(22)
	compactGapRow:SetPoint("TOPLEFT", page.UseIntegratedBank, "BOTTOMLEFT", 24, -14)
	compactGapRow:SetPoint("RIGHT", contentParent, "RIGHT", -14, 0)
	page.CompactCategoryGapRow = compactGapRow

	local compactGapLabel = compactGapRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	compactGapLabel:SetPoint("LEFT", compactGapRow, "LEFT", 0, 0)
	compactGapLabel:SetPoint("RIGHT", compactGapRow, "RIGHT", -172, 0)
	compactGapLabel:SetJustifyH("LEFT")
	compactGapLabel:SetJustifyV("MIDDLE")
	compactGapLabel:SetText(L["settingsCompactCategoryGapLabel"] or "Compact category gap")

	local compactGapStepper = CreateFrame("Frame", nil, compactGapRow)
	compactGapStepper:SetSize(156, 22)
	compactGapStepper:SetPoint("RIGHT", compactGapRow, "RIGHT", 0, 0)

	local compactGapDownButton = CreateFrame("Button", nil, compactGapStepper, "UIPanelButtonTemplate")
	compactGapDownButton:SetSize(24, 22)
	compactGapDownButton:SetPoint("LEFT", compactGapStepper, "LEFT", 0, 0)
	compactGapDownButton:SetText("-")
	setButtonFontObject(compactGapDownButton, GameFontNormalSmall)
	compactGapDownButton:SetScript("OnClick", function()
		local currentValue = addon.GetCompactCategoryGap and addon.GetCompactCategoryGap() or 8
		if addon.SetCompactCategoryGap and addon.SetCompactCategoryGap(currentValue - 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)

	local compactGapUpButton = CreateFrame("Button", nil, compactGapStepper, "UIPanelButtonTemplate")
	compactGapUpButton:SetSize(24, 22)
	compactGapUpButton:SetPoint("RIGHT", compactGapStepper, "RIGHT", 0, 0)
	compactGapUpButton:SetText("+")
	setButtonFontObject(compactGapUpButton, GameFontNormalSmall)
	compactGapUpButton:SetScript("OnClick", function()
		local currentValue = addon.GetCompactCategoryGap and addon.GetCompactCategoryGap() or 8
		if addon.SetCompactCategoryGap and addon.SetCompactCategoryGap(currentValue + 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)

	local compactGapValue = compactGapStepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	compactGapValue:SetPoint("LEFT", compactGapDownButton, "RIGHT", 10, 0)
	compactGapValue:SetPoint("RIGHT", compactGapUpButton, "LEFT", -10, 0)
	compactGapValue:SetJustifyH("CENTER")

	page.CompactCategoryGapControl = {
		Row = compactGapRow,
		Label = compactGapLabel,
		Stepper = compactGapStepper,
		DownButton = compactGapDownButton,
		UpButton = compactGapUpButton,
		Value = compactGapValue,
	}

	local treeIndentRow = CreateFrame("Frame", nil, contentParent)
	treeIndentRow:SetHeight(22)
	treeIndentRow:SetPoint("TOPLEFT", compactGapRow, "BOTTOMLEFT", 0, -10)
	treeIndentRow:SetPoint("RIGHT", contentParent, "RIGHT", -14, 0)
	page.CategoryTreeIndentRow = treeIndentRow

	local treeIndentLabel = treeIndentRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	treeIndentLabel:SetPoint("LEFT", treeIndentRow, "LEFT", 0, 0)
	treeIndentLabel:SetPoint("RIGHT", treeIndentRow, "RIGHT", -172, 0)
	treeIndentLabel:SetJustifyH("LEFT")
	treeIndentLabel:SetJustifyV("MIDDLE")
	treeIndentLabel:SetText(L["settingsCategoryTreeIndentLabel"] or "Tree category indent")

	local treeIndentStepper = CreateFrame("Frame", nil, treeIndentRow)
	treeIndentStepper:SetSize(156, 22)
	treeIndentStepper:SetPoint("RIGHT", treeIndentRow, "RIGHT", 0, 0)

	local treeIndentDownButton = CreateFrame("Button", nil, treeIndentStepper, "UIPanelButtonTemplate")
	treeIndentDownButton:SetSize(24, 22)
	treeIndentDownButton:SetPoint("LEFT", treeIndentStepper, "LEFT", 0, 0)
	treeIndentDownButton:SetText("-")
	setButtonFontObject(treeIndentDownButton, GameFontNormalSmall)
	treeIndentDownButton:SetScript("OnClick", function()
		local currentValue = addon.GetCategoryTreeIndent and addon.GetCategoryTreeIndent() or 14
		if addon.SetCategoryTreeIndent and addon.SetCategoryTreeIndent(currentValue - 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true, true)
		end
	end)

	local treeIndentUpButton = CreateFrame("Button", nil, treeIndentStepper, "UIPanelButtonTemplate")
	treeIndentUpButton:SetSize(24, 22)
	treeIndentUpButton:SetPoint("RIGHT", treeIndentStepper, "RIGHT", 0, 0)
	treeIndentUpButton:SetText("+")
	setButtonFontObject(treeIndentUpButton, GameFontNormalSmall)
	treeIndentUpButton:SetScript("OnClick", function()
		local currentValue = addon.GetCategoryTreeIndent and addon.GetCategoryTreeIndent() or 14
		if addon.SetCategoryTreeIndent and addon.SetCategoryTreeIndent(currentValue + 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true, true)
		end
	end)

	local treeIndentValue = treeIndentStepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	treeIndentValue:SetPoint("LEFT", treeIndentDownButton, "RIGHT", 10, 0)
	treeIndentValue:SetPoint("RIGHT", treeIndentUpButton, "LEFT", -10, 0)
	treeIndentValue:SetJustifyH("CENTER")

	page.CategoryTreeIndentControl = {
		Row = treeIndentRow,
		Label = treeIndentLabel,
		Stepper = treeIndentStepper,
		DownButton = treeIndentDownButton,
		UpButton = treeIndentUpButton,
		Value = treeIndentValue,
	}

	local resetButton = CreateFrame("Button", nil, contentParent, "UIPanelButtonTemplate")
	resetButton:SetSize(190, 22)
	resetButton:SetPoint("TOPLEFT", treeIndentRow, "BOTTOMLEFT", -20, -18)
	resetButton:SetText(L["settingsResetPosition"] or "Reset window position")
	resetButton:SetScript("OnClick", function()
		if Bags.functions and Bags.functions.ResetFramePosition then
			Bags.functions.ResetFramePosition()
		end
	end)
	page.ResetButton = resetButton

	local paddingCard = CreateFrame("Frame", nil, contentParent, "BackdropTemplate")
	paddingCard:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", -4, -18)
	paddingCard:SetPoint("RIGHT", contentParent, "RIGHT", -12, 0)
	paddingCard:SetHeight(258)
	createCardBackdrop(paddingCard)
	page.PaddingCard = paddingCard

	local paddingTitle = paddingCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	paddingTitle:SetPoint("TOPLEFT", paddingCard, "TOPLEFT", 14, -14)
	paddingTitle:SetText(L["settingsPaddingTitle"] or "Padding")
	page.PaddingTitle = paddingTitle

	local function createPaddingRow(parent, topOffset, labelText, getter, setter)
		local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, topOffset)
		label:SetPoint("RIGHT", parent, "RIGHT", -184, 0)
		label:SetJustifyH("LEFT")
		label:SetText(labelText)

		local stepper = CreateFrame("Frame", nil, parent)
		stepper:SetSize(156, 22)
		stepper:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, topOffset + 4)

		local downButton = CreateFrame("Button", nil, stepper, "UIPanelButtonTemplate")
		downButton:SetSize(24, 22)
		downButton:SetPoint("LEFT", stepper, "LEFT", 0, 0)
		downButton:SetText("-")
		setButtonFontObject(downButton, GameFontNormalSmall)
		downButton:SetScript("OnClick", function()
			local currentValue = getter and getter() or 0
			if setter and setter(currentValue - 1) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(false)
			end
		end)

		local upButton = CreateFrame("Button", nil, stepper, "UIPanelButtonTemplate")
		upButton:SetSize(24, 22)
		upButton:SetPoint("RIGHT", stepper, "RIGHT", 0, 0)
		upButton:SetText("+")
		setButtonFontObject(upButton, GameFontNormalSmall)
		upButton:SetScript("OnClick", function()
			local currentValue = getter and getter() or 0
			if setter and setter(currentValue + 1) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(false)
			end
		end)

		local value = stepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		value:SetPoint("LEFT", downButton, "RIGHT", 10, 0)
		value:SetPoint("RIGHT", upButton, "LEFT", -10, 0)
		value:SetJustifyH("CENTER")

		return {
			Label = label,
			Stepper = stepper,
			DownButton = downButton,
			UpButton = upButton,
			Value = value,
		}
	end

	page.OutsideHeaderPaddingControl = createPaddingRow(
		paddingCard,
		-40,
		L["settingsOutsideHeaderPaddingLabel"] or "Outside header",
		function()
			return addon.GetOutsideHeaderPadding and addon.GetOutsideHeaderPadding() or 0
		end,
		addon.SetOutsideHeaderPadding
	)

	page.OutsideFooterPaddingControl = createPaddingRow(
		paddingCard,
		-68,
		L["settingsOutsideFooterPaddingLabel"] or "Outside footer",
		function()
			return addon.GetOutsideFooterPadding and addon.GetOutsideFooterPadding() or 10
		end,
		addon.SetOutsideFooterPadding
	)

	page.InsideHorizontalPaddingControl = createPaddingRow(
		paddingCard,
		-96,
		L["settingsInsideHorizontalPaddingLabel"] or "Inside left + right",
		function()
			return addon.GetInsideHorizontalPadding and addon.GetInsideHorizontalPadding() or 10
		end,
		addon.SetInsideHorizontalPadding
	)

	page.InsideTopPaddingControl = createPaddingRow(
		paddingCard,
		-124,
		L["settingsInsideTopPaddingLabel"] or "Inside top",
		function()
			return addon.GetInsideTopPadding and addon.GetInsideTopPadding() or 10
		end,
		addon.SetInsideTopPadding
	)

	page.InsideBottomPaddingControl = createPaddingRow(
		paddingCard,
		-152,
		L["settingsInsideBottomPaddingLabel"] or "Inside bottom",
		function()
			return addon.GetInsideBottomPadding and addon.GetInsideBottomPadding() or 0
		end,
		addon.SetInsideBottomPadding
	)

	page.ItemScaleControl = createPaddingRow(
		paddingCard,
		-180,
		L["settingsItemScaleLabel"] or "Item scale",
		function()
			return addon.GetItemScale and addon.GetItemScale() or 100
		end,
		addon.SetItemScale
	)
	page.ItemScaleControl.DownButton:SetScript("OnClick", function()
		local currentValue = addon.GetItemScale and addon.GetItemScale() or 100
		if addon.SetItemScale and addon.SetItemScale(currentValue - 5) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)
	page.ItemScaleControl.UpButton:SetScript("OnClick", function()
		local currentValue = addon.GetItemScale and addon.GetItemScale() or 100
		if addon.SetItemScale and addon.SetItemScale(currentValue + 5) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)

	page.MaxColumnsControl = createPaddingRow(
		paddingCard,
		-208,
		L["settingsMaxColumnsLabel"] or "Max columns",
		function()
			return addon.GetMaxColumns and addon.GetMaxColumns() or 10
		end,
		addon.SetMaxColumns
	)
	page.MaxColumnsControl.DownButton:SetScript("OnClick", function()
		local currentValue = addon.GetMaxColumns and addon.GetMaxColumns() or 10
		if addon.SetMaxColumns and addon.SetMaxColumns(currentValue - 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)
	page.MaxColumnsControl.UpButton:SetScript("OnClick", function()
		local currentValue = addon.GetMaxColumns and addon.GetMaxColumns() or 10
		if addon.SetMaxColumns and addon.SetMaxColumns(currentValue + 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)

	local textAppearanceCard = CreateFrame("Frame", nil, contentParent, "BackdropTemplate")
	textAppearanceCard:SetPoint("TOPLEFT", paddingCard, "BOTTOMLEFT", 0, -18)
	textAppearanceCard:SetPoint("RIGHT", contentParent, "RIGHT", -12, 0)
	textAppearanceCard:SetHeight(836)
	createCardBackdrop(textAppearanceCard)
	page.TextAppearanceCard = textAppearanceCard

	local textAppearanceTitle = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	textAppearanceTitle:SetPoint("TOPLEFT", textAppearanceCard, "TOPLEFT", 14, -14)
	textAppearanceTitle:SetText(L["settingsTextAppearanceTitle"] or "Text appearance")
	page.TextAppearanceTitle = textAppearanceTitle

	local textAppearanceHint = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	textAppearanceHint:SetPoint("TOPLEFT", textAppearanceTitle, "BOTTOMLEFT", 0, -4)
	textAppearanceHint:SetPoint("RIGHT", textAppearanceCard, "RIGHT", -14, 0)
	textAppearanceHint:SetJustifyH("LEFT")
	textAppearanceHint:SetJustifyV("TOP")
	textAppearanceHint:SetText(L["settingsTextAppearanceHint"] or "Choose the font, size, and outline used for bag headers, footer text, and item overlays.")
	page.TextAppearanceHint = textAppearanceHint

	local textAppearanceControlWidth = 156
	local textAppearanceLeftInset = 14
	local textAppearanceControlGap = 16
	local textAppearanceRowGap = 12

	local function anchorTextAppearanceRow(label, control, previousControl)
		control:ClearAllPoints()
		if previousControl then
			control:SetPoint("TOPRIGHT", previousControl, "BOTTOMRIGHT", 0, -textAppearanceRowGap)
		else
			control:SetPoint("TOPRIGHT", textAppearanceHint, "BOTTOMRIGHT", 0, -16)
		end

		label:ClearAllPoints()
		label:SetPoint("LEFT", textAppearanceCard, "LEFT", textAppearanceLeftInset, 0)
		label:SetPoint("RIGHT", control, "LEFT", -textAppearanceControlGap, 0)
		label:SetPoint("TOP", control, "TOP", 0, 0)
		label:SetPoint("BOTTOM", control, "BOTTOM", 0, 0)
		label:SetJustifyH("LEFT")
		label:SetJustifyV("MIDDLE")
	end

	local skinPresetLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	skinPresetLabel:SetText(L["settingsSkinPresetLabel"] or "Skin")
	page.SkinPresetLabel = skinPresetLabel

	local skinPresetButton = CreateFrame("Button", nil, textAppearanceCard, "UIPanelButtonTemplate")
	skinPresetButton:SetSize(textAppearanceControlWidth, 22)
	setButtonFontObject(skinPresetButton, GameFontNormalSmall)
	skinPresetButton:SetScript("OnClick", function(self)
		openSimpleRadioMenu(self, addon.GetSkinPresetOptions and addon.GetSkinPresetOptions() or {}, addon.GetSkinPreset and addon.GetSkinPreset() or "default", function(value)
			if addon.SetSkinPreset and addon.SetSkinPreset(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	page.SkinPresetButton = skinPresetButton
	anchorTextAppearanceRow(skinPresetLabel, skinPresetButton)

	local iconShapeLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	iconShapeLabel:SetText(L["settingsIconShapeLabel"] or "Icon shape")
	page.IconShapeLabel = iconShapeLabel

	local iconShapeButton = CreateFrame("Button", nil, textAppearanceCard, "UIPanelButtonTemplate")
	iconShapeButton:SetSize(textAppearanceControlWidth, 22)
	setButtonFontObject(iconShapeButton, GameFontNormalSmall)
	iconShapeButton:SetScript("OnClick", function(self)
		openSimpleRadioMenu(self, addon.GetIconShapeOptions and addon.GetIconShapeOptions() or {}, addon.GetIconShape and addon.GetIconShape() or "preset", function(value)
			if addon.SetIconShape and addon.SetIconShape(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	page.IconShapeButton = iconShapeButton
	anchorTextAppearanceRow(iconShapeLabel, iconShapeButton, skinPresetButton)

	local freeSlotDisplayLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	freeSlotDisplayLabel:SetText(L["settingsFreeSlotDisplayLabel"] or "Free slot display")
	page.FreeSlotDisplayLabel = freeSlotDisplayLabel

	local freeSlotDisplayButton = CreateFrame("Button", nil, textAppearanceCard, "UIPanelButtonTemplate")
	freeSlotDisplayButton:SetSize(textAppearanceControlWidth, 22)
	setButtonFontObject(freeSlotDisplayButton, GameFontNormalSmall)
	freeSlotDisplayButton:SetScript("OnClick", function(self)
		openSimpleRadioMenu(self, addon.GetFreeSlotDisplayModeOptions and addon.GetFreeSlotDisplayModeOptions() or {}, addon.GetFreeSlotDisplayMode and addon.GetFreeSlotDisplayMode() or "icons", function(value)
			if addon.SetFreeSlotDisplayMode and addon.SetFreeSlotDisplayMode(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	page.FreeSlotDisplayButton = freeSlotDisplayButton
	anchorTextAppearanceRow(freeSlotDisplayLabel, freeSlotDisplayButton, iconShapeButton)

	local freeSlotNormalColorLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	freeSlotNormalColorLabel:SetText(L["settingsFreeSlotNormalColor"] or "Bag free slot color")
	page.FreeSlotNormalColorLabel = freeSlotNormalColorLabel

	local freeSlotNormalColorSwatch = CreateFrame("Button", nil, textAppearanceCard, "ColorSwatchTemplate")
	freeSlotNormalColorSwatch:SetSize(22, 22)
	freeSlotNormalColorSwatch:SetScript("OnClick", function()
		if addon.GetFreeSlotDisplayMode and addon.GetFreeSlotDisplayMode() ~= "colors" then
			return
		end
		openColorPicker(addon.GetFreeSlotColor and addon.GetFreeSlotColor("normal") or { 1, 1, 1 }, function(r, g, b)
			if addon.SetFreeSlotColor and addon.SetFreeSlotColor("normal", r, g, b) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	page.FreeSlotNormalColorSwatch = freeSlotNormalColorSwatch
	anchorTextAppearanceRow(freeSlotNormalColorLabel, freeSlotNormalColorSwatch, freeSlotDisplayButton)

	local freeSlotReagentColorLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	freeSlotReagentColorLabel:SetText(L["settingsFreeSlotReagentColor"] or "Reagent free slot color")
	page.FreeSlotReagentColorLabel = freeSlotReagentColorLabel

	local freeSlotReagentColorSwatch = CreateFrame("Button", nil, textAppearanceCard, "ColorSwatchTemplate")
	freeSlotReagentColorSwatch:SetSize(22, 22)
	freeSlotReagentColorSwatch:SetScript("OnClick", function()
		if addon.GetFreeSlotDisplayMode and addon.GetFreeSlotDisplayMode() ~= "colors" then
			return
		end
		openColorPicker(addon.GetFreeSlotColor and addon.GetFreeSlotColor("reagent") or { 1, 1, 1 }, function(r, g, b)
			if addon.SetFreeSlotColor and addon.SetFreeSlotColor("reagent", r, g, b) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	page.FreeSlotReagentColorSwatch = freeSlotReagentColorSwatch
	anchorTextAppearanceRow(freeSlotReagentColorLabel, freeSlotReagentColorSwatch, freeSlotNormalColorSwatch)

	local frameBackgroundLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frameBackgroundLabel:SetText(L["settingsFrameBackgroundLabel"] or "Background")
	page.FrameBackgroundLabel = frameBackgroundLabel

	local frameBackgroundButton = CreateFrame("Button", nil, textAppearanceCard, "UIPanelButtonTemplate")
	frameBackgroundButton:SetSize(textAppearanceControlWidth, 22)
	setButtonFontObject(frameBackgroundButton, GameFontNormalSmall)
	frameBackgroundButton:SetScript("OnClick", function(self)
		openSimpleRadioMenu(self, addon.GetFrameBackgroundOptions and addon.GetFrameBackgroundOptions() or {}, addon.GetFrameBackground and addon.GetFrameBackground() or "solid", function(value)
			if addon.SetFrameBackground and addon.SetFrameBackground(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	page.FrameBackgroundButton = frameBackgroundButton
	anchorTextAppearanceRow(frameBackgroundLabel, frameBackgroundButton, freeSlotReagentColorSwatch)

	local frameBackgroundColorLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frameBackgroundColorLabel:SetText(L["Background color"] or "Background color")
	page.FrameBackgroundColorLabel = frameBackgroundColorLabel

	local frameBackgroundColorSwatch = CreateFrame("Button", nil, textAppearanceCard, "ColorSwatchTemplate")
	frameBackgroundColorSwatch:SetSize(22, 22)
	frameBackgroundColorSwatch:SetScript("OnClick", function()
		local color = addon.GetFrameBackgroundColor and addon.GetFrameBackgroundColor() or { 0.03, 0.03, 0.04 }
		openColorPicker(color, function(r, g, b)
			if addon.SetFrameBackgroundColor and addon.SetFrameBackgroundColor(r, g, b) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	frameBackgroundColorSwatch:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["Background color"] or "Background color")
		GameTooltip:Show()
	end)
	frameBackgroundColorSwatch:HookScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	page.FrameBackgroundColorSwatch = frameBackgroundColorSwatch
	anchorTextAppearanceRow(frameBackgroundColorLabel, frameBackgroundColorSwatch, frameBackgroundButton)

	local backgroundOpacityLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	backgroundOpacityLabel:SetText(L["settingsFrameBackgroundOpacityLabel"] or "Background opacity")
	page.FrameBackgroundOpacityLabel = backgroundOpacityLabel

	local backgroundOpacityStepper = CreateFrame("Frame", nil, textAppearanceCard)
	backgroundOpacityStepper:SetSize(textAppearanceControlWidth, 22)
	page.FrameBackgroundOpacityStepper = backgroundOpacityStepper
	anchorTextAppearanceRow(backgroundOpacityLabel, backgroundOpacityStepper, frameBackgroundColorSwatch)

	local backgroundOpacityDownButton = CreateFrame("Button", nil, backgroundOpacityStepper, "UIPanelButtonTemplate")
	backgroundOpacityDownButton:SetSize(24, 22)
	backgroundOpacityDownButton:SetPoint("LEFT", backgroundOpacityStepper, "LEFT", 0, 0)
	backgroundOpacityDownButton:SetText("-")
	setButtonFontObject(backgroundOpacityDownButton, GameFontNormalSmall)
	backgroundOpacityDownButton:SetScript("OnClick", function()
		local currentOpacity = addon.GetFrameBackgroundOpacity and addon.GetFrameBackgroundOpacity() or 60
		if addon.SetFrameBackgroundOpacity and addon.SetFrameBackgroundOpacity(currentOpacity - 5) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)
	page.FrameBackgroundOpacityDownButton = backgroundOpacityDownButton

	local backgroundOpacityUpButton = CreateFrame("Button", nil, backgroundOpacityStepper, "UIPanelButtonTemplate")
	backgroundOpacityUpButton:SetSize(24, 22)
	backgroundOpacityUpButton:SetPoint("RIGHT", backgroundOpacityStepper, "RIGHT", 0, 0)
	backgroundOpacityUpButton:SetText("+")
	setButtonFontObject(backgroundOpacityUpButton, GameFontNormalSmall)
	backgroundOpacityUpButton:SetScript("OnClick", function()
		local currentOpacity = addon.GetFrameBackgroundOpacity and addon.GetFrameBackgroundOpacity() or 60
		if addon.SetFrameBackgroundOpacity and addon.SetFrameBackgroundOpacity(currentOpacity + 5) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)
	page.FrameBackgroundOpacityUpButton = backgroundOpacityUpButton

	local backgroundOpacityValue = backgroundOpacityStepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	backgroundOpacityValue:SetPoint("LEFT", backgroundOpacityDownButton, "RIGHT", 10, 0)
	backgroundOpacityValue:SetPoint("RIGHT", backgroundOpacityUpButton, "LEFT", -10, 0)
	backgroundOpacityValue:SetJustifyH("CENTER")
	page.FrameBackgroundOpacityValue = backgroundOpacityValue

	local frameBorderTextureLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frameBorderTextureLabel:SetText(L["settingsFrameBorderTextureLabel"] or "Border texture")
	page.FrameBorderTextureLabel = frameBorderTextureLabel

	local frameBorderTextureButton = CreateFrame("Button", nil, textAppearanceCard, "UIPanelButtonTemplate")
	frameBorderTextureButton:SetSize(textAppearanceControlWidth, 22)
	setButtonFontObject(frameBorderTextureButton, GameFontNormalSmall)
	frameBorderTextureButton:SetScript("OnClick", function(self)
		openSimpleRadioMenu(self, addon.GetFrameBorderTextureOptions and addon.GetFrameBorderTextureOptions() or {}, addon.GetFrameBorderTexture and addon.GetFrameBorderTexture() or "__skin__", function(value)
			if addon.SetFrameBorderTexture and addon.SetFrameBorderTexture(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	page.FrameBorderTextureButton = frameBorderTextureButton
	anchorTextAppearanceRow(frameBorderTextureLabel, frameBorderTextureButton, backgroundOpacityStepper)

	local frameBorderColorLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frameBorderColorLabel:SetText(L["settingsFrameBorderColorLabel"] or "Border color")
	page.FrameBorderColorLabel = frameBorderColorLabel

	local frameBorderColorSwatch = CreateFrame("Button", nil, textAppearanceCard, "ColorSwatchTemplate")
	frameBorderColorSwatch:SetSize(22, 22)
	frameBorderColorSwatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frameBorderColorSwatch:SetScript("OnClick", function(_, button)
		if button == "RightButton" then
			if addon.ClearFrameBorderColor and addon.ClearFrameBorderColor() then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
			return
		end

		local skin = addon.GetActiveSkinDefinition and addon.GetActiveSkinDefinition() or nil
		local color = addon.GetFrameBorderColor and addon.GetFrameBorderColor(skin and skin.frame and skin.frame.borderColor) or { 0.35, 0.35, 0.42, 1 }
		openColorPicker(color, function(r, g, b)
			if addon.SetFrameBorderColor and addon.SetFrameBorderColor(r, g, b) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
	end)
	frameBorderColorSwatch:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["settingsFrameBorderColorLabel"] or "Border color")
		GameTooltip:AddLine(L["settingsFrameBorderColorTooltip"] or "Right-click to follow the selected skin color.", 0.78, 0.78, 0.78, true)
		GameTooltip:Show()
	end)
	frameBorderColorSwatch:HookScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	page.FrameBorderColorSwatch = frameBorderColorSwatch
	anchorTextAppearanceRow(frameBorderColorLabel, frameBorderColorSwatch, frameBorderTextureButton)

	local frameBorderSizeLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frameBorderSizeLabel:SetText(L["settingsFrameBorderSizeLabel"] or "Border size")
	page.FrameBorderSizeLabel = frameBorderSizeLabel

	local frameBorderSizeStepper = CreateFrame("Frame", nil, textAppearanceCard)
	frameBorderSizeStepper:SetSize(textAppearanceControlWidth, 22)
	page.FrameBorderSizeStepper = frameBorderSizeStepper
	anchorTextAppearanceRow(frameBorderSizeLabel, frameBorderSizeStepper, frameBorderColorSwatch)

	local frameBorderSizeDownButton = CreateFrame("Button", nil, frameBorderSizeStepper, "UIPanelButtonTemplate")
	frameBorderSizeDownButton:SetSize(24, 22)
	frameBorderSizeDownButton:SetPoint("LEFT", frameBorderSizeStepper, "LEFT", 0, 0)
	frameBorderSizeDownButton:SetText("-")
	setButtonFontObject(frameBorderSizeDownButton, GameFontNormalSmall)
	frameBorderSizeDownButton:SetScript("OnClick", function()
		local currentSize = addon.GetFrameBorderSize and addon.GetFrameBorderSize() or 1
		if addon.SetFrameBorderSize and addon.SetFrameBorderSize(currentSize - 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)
	page.FrameBorderSizeDownButton = frameBorderSizeDownButton

	local frameBorderSizeUpButton = CreateFrame("Button", nil, frameBorderSizeStepper, "UIPanelButtonTemplate")
	frameBorderSizeUpButton:SetSize(24, 22)
	frameBorderSizeUpButton:SetPoint("RIGHT", frameBorderSizeStepper, "RIGHT", 0, 0)
	frameBorderSizeUpButton:SetText("+")
	setButtonFontObject(frameBorderSizeUpButton, GameFontNormalSmall)
	frameBorderSizeUpButton:SetScript("OnClick", function()
		local currentSize = addon.GetFrameBorderSize and addon.GetFrameBorderSize() or 1
		if addon.SetFrameBorderSize and addon.SetFrameBorderSize(currentSize + 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)
	page.FrameBorderSizeUpButton = frameBorderSizeUpButton

	local frameBorderSizeValue = frameBorderSizeStepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frameBorderSizeValue:SetPoint("LEFT", frameBorderSizeDownButton, "RIGHT", 10, 0)
	frameBorderSizeValue:SetPoint("RIGHT", frameBorderSizeUpButton, "LEFT", -10, 0)
	frameBorderSizeValue:SetJustifyH("CENTER")
	page.FrameBorderSizeValue = frameBorderSizeValue

	local frameBorderOffsetLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frameBorderOffsetLabel:SetText(L["settingsFrameBorderOffsetLabel"] or "Border offset")
	page.FrameBorderOffsetLabel = frameBorderOffsetLabel

	local frameBorderOffsetStepper = CreateFrame("Frame", nil, textAppearanceCard)
	frameBorderOffsetStepper:SetSize(textAppearanceControlWidth, 22)
	page.FrameBorderOffsetStepper = frameBorderOffsetStepper
	anchorTextAppearanceRow(frameBorderOffsetLabel, frameBorderOffsetStepper, frameBorderSizeStepper)

	local frameBorderOffsetDownButton = CreateFrame("Button", nil, frameBorderOffsetStepper, "UIPanelButtonTemplate")
	frameBorderOffsetDownButton:SetSize(24, 22)
	frameBorderOffsetDownButton:SetPoint("LEFT", frameBorderOffsetStepper, "LEFT", 0, 0)
	frameBorderOffsetDownButton:SetText("-")
	setButtonFontObject(frameBorderOffsetDownButton, GameFontNormalSmall)
	frameBorderOffsetDownButton:SetScript("OnClick", function()
		local currentOffset = addon.GetFrameBorderOffset and addon.GetFrameBorderOffset() or 0
		if addon.SetFrameBorderOffset and addon.SetFrameBorderOffset(currentOffset - 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)
	page.FrameBorderOffsetDownButton = frameBorderOffsetDownButton

	local frameBorderOffsetUpButton = CreateFrame("Button", nil, frameBorderOffsetStepper, "UIPanelButtonTemplate")
	frameBorderOffsetUpButton:SetSize(24, 22)
	frameBorderOffsetUpButton:SetPoint("RIGHT", frameBorderOffsetStepper, "RIGHT", 0, 0)
	frameBorderOffsetUpButton:SetText("+")
	setButtonFontObject(frameBorderOffsetUpButton, GameFontNormalSmall)
	frameBorderOffsetUpButton:SetScript("OnClick", function()
		local currentOffset = addon.GetFrameBorderOffset and addon.GetFrameBorderOffset() or 0
		if addon.SetFrameBorderOffset and addon.SetFrameBorderOffset(currentOffset + 1) then
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(true)
		end
	end)
	page.FrameBorderOffsetUpButton = frameBorderOffsetUpButton

	local frameBorderOffsetValue = frameBorderOffsetStepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frameBorderOffsetValue:SetPoint("LEFT", frameBorderOffsetDownButton, "RIGHT", 10, 0)
	frameBorderOffsetValue:SetPoint("RIGHT", frameBorderOffsetUpButton, "LEFT", -10, 0)
	frameBorderOffsetValue:SetJustifyH("CENTER")
	page.FrameBorderOffsetValue = frameBorderOffsetValue

	local fontLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fontLabel:SetText(L["settingsTextFontLabel"] or "Font")
	page.TextFontLabel = fontLabel

	local fontButton = CreateFrame("Button", nil, textAppearanceCard, "UIPanelButtonTemplate")
	fontButton:SetSize(textAppearanceControlWidth, 22)
	setButtonFontObject(fontButton, GameFontNormalSmall)
	fontButton:SetScript("OnClick", function(self)
		local appearance = addon.GetTextAppearance and addon.GetTextAppearance() or {}
		openSimpleRadioMenu(self, addon.GetTextFontOptions and addon.GetTextFontOptions() or {}, appearance.font, function(value)
			if addon.SetTextAppearanceFont and addon.SetTextAppearanceFont(value) then
				addon.RefreshSettingsFrame()
				requestBagRefresh(true)
			end
		end)
	end)
	page.TextFontButton = fontButton
	anchorTextAppearanceRow(fontLabel, fontButton, frameBorderOffsetStepper)

	local sizeLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	sizeLabel:SetText(L["settingsTextSizeLabel"] or "Size")
	page.TextSizeLabel = sizeLabel

	local sizeStepper = CreateFrame("Frame", nil, textAppearanceCard)
	sizeStepper:SetSize(textAppearanceControlWidth, 22)
	page.TextSizeStepper = sizeStepper
	anchorTextAppearanceRow(sizeLabel, sizeStepper, fontButton)

	local sizeDownButton = CreateFrame("Button", nil, sizeStepper, "UIPanelButtonTemplate")
	sizeDownButton:SetSize(24, 22)
	sizeDownButton:SetPoint("LEFT", sizeStepper, "LEFT", 0, 0)
	sizeDownButton:SetText("-")
	setButtonFontObject(sizeDownButton, GameFontNormalSmall)
	sizeDownButton:SetScript("OnClick", function()
		local appearance = addon.GetTextAppearance and addon.GetTextAppearance()
		local currentSize = tonumber(appearance and appearance.size) or 12
		if addon.SetTextAppearanceSize and addon.SetTextAppearanceSize(currentSize - 1) then
			addon.RefreshSettingsFrame()
			requestBagRefresh(true)
		end
	end)
	page.TextSizeDownButton = sizeDownButton

	local sizeUpButton = CreateFrame("Button", nil, sizeStepper, "UIPanelButtonTemplate")
	sizeUpButton:SetSize(24, 22)
	sizeUpButton:SetPoint("RIGHT", sizeStepper, "RIGHT", 0, 0)
	sizeUpButton:SetText("+")
	setButtonFontObject(sizeUpButton, GameFontNormalSmall)
	sizeUpButton:SetScript("OnClick", function()
		local appearance = addon.GetTextAppearance and addon.GetTextAppearance()
		local currentSize = tonumber(appearance and appearance.size) or 12
		if addon.SetTextAppearanceSize and addon.SetTextAppearanceSize(currentSize + 1) then
			addon.RefreshSettingsFrame()
			requestBagRefresh(true)
		end
	end)
	page.TextSizeUpButton = sizeUpButton

	local sizeValue = sizeStepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	sizeValue:SetPoint("LEFT", sizeDownButton, "RIGHT", 10, 0)
	sizeValue:SetPoint("RIGHT", sizeUpButton, "LEFT", -10, 0)
	sizeValue:SetJustifyH("CENTER")
	page.TextSizeValue = sizeValue

	local overlaySizeLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	overlaySizeLabel:SetText(L["settingsTextOverlaySizeLabel"] or "Overlay size")
	page.TextOverlaySizeLabel = overlaySizeLabel

	local overlaySizeStepper = CreateFrame("Frame", nil, textAppearanceCard)
	overlaySizeStepper:SetSize(textAppearanceControlWidth, 22)
	page.TextOverlaySizeStepper = overlaySizeStepper
	anchorTextAppearanceRow(overlaySizeLabel, overlaySizeStepper, sizeStepper)

	local overlaySizeDownButton = CreateFrame("Button", nil, overlaySizeStepper, "UIPanelButtonTemplate")
	overlaySizeDownButton:SetSize(24, 22)
	overlaySizeDownButton:SetPoint("LEFT", overlaySizeStepper, "LEFT", 0, 0)
	overlaySizeDownButton:SetText("-")
	setButtonFontObject(overlaySizeDownButton, GameFontNormalSmall)
	overlaySizeDownButton:SetScript("OnClick", function()
		local currentSize = addon.GetTextAppearanceOverlaySize and addon.GetTextAppearanceOverlaySize() or 12
		if addon.SetTextAppearanceOverlaySize and addon.SetTextAppearanceOverlaySize(currentSize - 1) then
			addon.RefreshSettingsFrame()
			requestBagRefresh(false)
		end
	end)
	page.TextOverlaySizeDownButton = overlaySizeDownButton

	local overlaySizeUpButton = CreateFrame("Button", nil, overlaySizeStepper, "UIPanelButtonTemplate")
	overlaySizeUpButton:SetSize(24, 22)
	overlaySizeUpButton:SetPoint("RIGHT", overlaySizeStepper, "RIGHT", 0, 0)
	overlaySizeUpButton:SetText("+")
	setButtonFontObject(overlaySizeUpButton, GameFontNormalSmall)
	overlaySizeUpButton:SetScript("OnClick", function()
		local currentSize = addon.GetTextAppearanceOverlaySize and addon.GetTextAppearanceOverlaySize() or 12
		if addon.SetTextAppearanceOverlaySize and addon.SetTextAppearanceOverlaySize(currentSize + 1) then
			addon.RefreshSettingsFrame()
			requestBagRefresh(false)
		end
	end)
	page.TextOverlaySizeUpButton = overlaySizeUpButton

	local overlaySizeValue = overlaySizeStepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	overlaySizeValue:SetPoint("LEFT", overlaySizeDownButton, "RIGHT", 10, 0)
	overlaySizeValue:SetPoint("RIGHT", overlaySizeUpButton, "LEFT", -10, 0)
	overlaySizeValue:SetJustifyH("CENTER")
	page.TextOverlaySizeValue = overlaySizeValue

	local outlineLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	outlineLabel:SetText(L["settingsTextOutlineLabel"] or "Outline")
	page.TextOutlineLabel = outlineLabel

	local outlineButton = CreateFrame("Button", nil, textAppearanceCard, "UIPanelButtonTemplate")
	outlineButton:SetSize(textAppearanceControlWidth, 22)
	setButtonFontObject(outlineButton, GameFontNormalSmall)
	outlineButton:SetScript("OnClick", function(self)
		local appearance = addon.GetTextAppearance and addon.GetTextAppearance() or {}
		openSimpleRadioMenu(self, addon.GetTextOutlineOptions and addon.GetTextOutlineOptions() or {}, appearance.outline, function(value)
			if addon.SetTextAppearanceOutline and addon.SetTextAppearanceOutline(value) then
				addon.RefreshSettingsFrame()
				requestBagRefresh(true)
			end
		end)
	end)
	page.TextOutlineButton = outlineButton
	anchorTextAppearanceRow(outlineLabel, outlineButton, overlaySizeStepper)

	local textStylesTitle = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	textStylesTitle:SetPoint("LEFT", textAppearanceCard, "LEFT", textAppearanceLeftInset, 0)
	textStylesTitle:SetPoint("TOP", outlineButton, "BOTTOM", 0, -textAppearanceRowGap - 8)
	textStylesTitle:SetText(L["settingsTextStylesTitle"] or "Text styles")
	page.TextStylesTitle = textStylesTitle

	local textStyleRows = {}
	local function createTextStyleRow(elementID, previousRow)
		local row = CreateFrame("Frame", nil, textAppearanceCard)
		row:SetHeight(42)
		row:SetPoint("LEFT", textAppearanceCard, "LEFT", textAppearanceLeftInset, 0)
		row:SetPoint("RIGHT", textAppearanceCard, "RIGHT", -14, 0)
		if previousRow then
			row:SetPoint("TOP", previousRow, "BOTTOM", 0, -10)
		else
			row:SetPoint("TOP", textStylesTitle, "BOTTOM", 0, -8)
		end
		row.ElementID = elementID

		local elementOptions = addon.GetTextElementOptions and addon.GetTextElementOptions() or {}
		local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
		label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
		label:SetJustifyH("LEFT")
		label:SetJustifyV("TOP")
		label:SetText(getOptionLabel(elementOptions, elementID, elementID))
		setSingleLineText(label)
		row.Label = label

		local outline = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		outline:SetSize(122, 22)
		outline:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
		setButtonFontObject(outline, GameFontNormalSmall)
		outline:SetScript("OnClick", function(self)
			local element = addon.GetTextElementAppearance and addon.GetTextElementAppearance(elementID) or {}
			openSimpleRadioMenu(self, addon.GetTextElementOutlineOptions and addon.GetTextElementOutlineOptions() or {}, element.outline, function(value)
				if addon.SetTextElementOutline and addon.SetTextElementOutline(elementID, value) then
					addon.RefreshSettingsFrame("layout")
					requestBagRefresh(true)
				end
			end)
		end)
		row.OutlineButton = outline

		local stackAnchor = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		stackAnchor:SetSize(104, 22)
		stackAnchor:SetPoint("RIGHT", outline, "LEFT", -6, 0)
		stackAnchor:SetShown(elementID == "stackCount")
		setButtonFontObject(stackAnchor, GameFontNormalSmall)
		stackAnchor:SetScript("OnClick", function(self)
			openSimpleRadioMenu(self, addon.GetStackCountAnchorOptions and addon.GetStackCountAnchorOptions() or {}, addon.GetStackCountAnchor and addon.GetStackCountAnchor() or "BOTTOMRIGHT", function(value)
				if addon.SetStackCountAnchor and addon.SetStackCountAnchor(value) then
					addon.RefreshSettingsFrame("layout")
					requestBagRefresh(false, true)
				end
			end)
		end)
		setTooltipScripts(stackAnchor, L["settingsOverlayAnchorLabel"] or "Anchor", nil)
		row.StackAnchorButton = stackAnchor

		local case = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		case:SetSize(78, 22)
		case:SetPoint("RIGHT", outline, "LEFT", -6, 0)
		case:SetShown(elementID ~= "stackCount")
		setButtonFontObject(case, GameFontNormalSmall)
		case:SetScript("OnClick", function(self)
			local element = addon.GetTextElementAppearance and addon.GetTextElementAppearance(elementID) or {}
			openSimpleRadioMenu(self, addon.GetTextCaseOptions and addon.GetTextCaseOptions() or {}, element.case or "default", function(value)
				if addon.SetTextElementCase and addon.SetTextElementCase(elementID, value) then
					addon.RefreshSettingsFrame("layout")
					requestBagRefresh(true)
				end
			end)
		end)
		row.CaseButton = case

		local sizeStepper = CreateFrame("Frame", nil, row)
		sizeStepper:SetSize(74, 22)
		if elementID == "stackCount" then
			sizeStepper:SetPoint("RIGHT", stackAnchor, "LEFT", -6, 0)
		else
			sizeStepper:SetPoint("RIGHT", case, "LEFT", -6, 0)
		end
		row.SizeStepper = sizeStepper

		local sizeDown = CreateFrame("Button", nil, sizeStepper, "UIPanelButtonTemplate")
		sizeDown:SetSize(20, 22)
		sizeDown:SetPoint("LEFT", sizeStepper, "LEFT", 0, 0)
		sizeDown:SetText("-")
		setButtonFontObject(sizeDown, GameFontNormalSmall)
		sizeDown:SetScript("OnClick", function()
			local element = addon.GetTextElementAppearance and addon.GetTextElementAppearance(elementID) or {}
			if addon.SetTextElementSize and addon.SetTextElementSize(elementID, (tonumber(element.size) or 12) - 1) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
		row.SizeDownButton = sizeDown

		local sizeUp = CreateFrame("Button", nil, sizeStepper, "UIPanelButtonTemplate")
		sizeUp:SetSize(20, 22)
		sizeUp:SetPoint("RIGHT", sizeStepper, "RIGHT", 0, 0)
		sizeUp:SetText("+")
		setButtonFontObject(sizeUp, GameFontNormalSmall)
		sizeUp:SetScript("OnClick", function()
			local element = addon.GetTextElementAppearance and addon.GetTextElementAppearance(elementID) or {}
			if addon.SetTextElementSize and addon.SetTextElementSize(elementID, (tonumber(element.size) or 12) + 1) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end)
		row.SizeUpButton = sizeUp

		local sizeValue = sizeStepper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		sizeValue:SetPoint("LEFT", sizeDown, "RIGHT", 4, 0)
		sizeValue:SetPoint("RIGHT", sizeUp, "LEFT", -4, 0)
		sizeValue:SetJustifyH("CENTER")
		row.SizeValue = sizeValue

		local font = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		font:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
		font:SetPoint("RIGHT", sizeStepper, "LEFT", -6, 0)
		font:SetHeight(22)
		setButtonFontObject(font, GameFontNormalSmall)
		font:SetScript("OnClick", function(self)
			local element = addon.GetTextElementAppearance and addon.GetTextElementAppearance(elementID) or {}
			openSimpleRadioMenu(self, addon.GetTextElementFontOptions and addon.GetTextElementFontOptions() or {}, element.font, function(value)
				if addon.SetTextElementFont and addon.SetTextElementFont(elementID, value) then
					addon.RefreshSettingsFrame("layout")
					requestBagRefresh(true)
				end
			end)
		end)
		row.FontButton = font

		textStyleRows[#textStyleRows + 1] = row
		return row
	end

	local previousTextStyleRow
	for _, elementID in ipairs({ "categoryHeader", "subcategoryHeader", "overlays", "stackCount" }) do
		previousTextStyleRow = createTextStyleRow(elementID, previousTextStyleRow)
	end
	page.TextStyleRows = textStyleRows

	local subcategoryFullLabels = createInlineCheckbox(
		textAppearanceCard,
		L["settingsSubcategoryFullLabels"] or "Use free row space for subcategory names",
		L["settingsSubcategoryFullLabelsTooltip"] or "Allows compact subcategories to grow wide enough for their full label when there is room.",
		function(value)
			if addon.SetSubcategoryFullLabels and addon.SetSubcategoryFullLabels(value) then
				addon.RefreshSettingsFrame("layout")
				requestBagRefresh(true)
			end
		end
	)
	page.SubcategoryFullLabels = subcategoryFullLabels
	if previousTextStyleRow then
		subcategoryFullLabels:SetPoint("TOPLEFT", previousTextStyleRow, "BOTTOMLEFT", -4, -10)
	else
		subcategoryFullLabels:SetPoint("TOPLEFT", textStylesTitle, "BOTTOMLEFT", -4, -10)
	end
	if subcategoryFullLabels.Label then
		subcategoryFullLabels.Label:SetPoint("RIGHT", textAppearanceCard, "RIGHT", -14, 0)
		subcategoryFullLabels.Label:SetWordWrap(false)
	end

	local previewLabel = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	previewLabel:SetPoint("LEFT", textAppearanceCard, "LEFT", textAppearanceLeftInset, 0)
	previewLabel:SetPoint("TOP", subcategoryFullLabels, "BOTTOM", 0, -textAppearanceRowGap - 6)
	previewLabel:SetText(L["settingsOverlayPreviewLabel"] or "Preview")
	page.TextPreviewLabel = previewLabel

	local preview = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	preview:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -6)
	preview:SetPoint("RIGHT", textAppearanceCard, "RIGHT", -14, 0)
	preview:SetJustifyH("LEFT")
	preview:SetText(L["simpleBagsTitle"] or "Bags")
	preview:SetTextColor(1, 0.82, 0.16)
	page.TextPreview = preview

	local overlayPreview = textAppearanceCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	overlayPreview:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -4)
	overlayPreview:SetPoint("RIGHT", textAppearanceCard, "RIGHT", -14, 0)
	overlayPreview:SetJustifyH("LEFT")
	overlayPreview:SetText("278   4/6   x99")
	page.TextOverlayPreview = overlayPreview

	updateScrollContainer(scrollFrame, content, page.LayoutContentHeight)

	return page
end

refreshLayoutPage = function(page)
	if not page then
		return
	end

	applyLayoutPageMode(page)

	local settings = getSettings()
	local appearance = addon.GetTextAppearance and addon.GetTextAppearance() or {}
	local oneBagMode = addon.GetOneBagMode and addon.GetOneBagMode() or settings.oneBagMode == true

	if page.OneBagMode then
		page.OneBagMode:SetChecked(oneBagMode)
	end
	if page.OneBagFreeSlotsAtEnd then
		page.OneBagFreeSlotsAtEnd:SetChecked(addon.GetOneBagFreeSlotsAtEnd and addon.GetOneBagFreeSlotsAtEnd() or settings.oneBagFreeSlotsAtEnd == true)
	end
	if page.ShowCategories then
		page.ShowCategories:SetChecked(settings.showCategories)
		page.ShowCategories:SetEnabled(not oneBagMode)
		page.ShowCategories:SetAlpha(oneBagMode and 0.45 or 1)
		if page.ShowCategories.Label then
			page.ShowCategories.Label:SetAlpha(oneBagMode and 0.45 or 1)
		end
	end
	if page.CombineFreeSlots then
		page.CombineFreeSlots:SetChecked(settings.combineFreeSlots)
		page.CombineFreeSlots:SetEnabled(not oneBagMode)
		page.CombineFreeSlots:SetAlpha(oneBagMode and 0.45 or 1)
		if page.CombineFreeSlots.Label then
			page.CombineFreeSlots.Label:SetAlpha(oneBagMode and 0.45 or 1)
		end
	end
	if page.ShowFreeSlots then
		page.ShowFreeSlots:SetChecked(addon.GetShowFreeSlots == nil or addon.GetShowFreeSlots())
	end
	if page.CombineDuplicateItems then
		page.CombineDuplicateItems:SetChecked(settings.combineUnstackableItems)
		page.CombineDuplicateItems:SetEnabled(not oneBagMode)
		page.CombineDuplicateItems:SetAlpha(oneBagMode and 0.45 or 1)
		if page.CombineDuplicateItems.Label then
			page.CombineDuplicateItems.Label:SetAlpha(oneBagMode and 0.45 or 1)
		end
	end
	if page.ClearNewItemsOnHeaderClick then
		page.ClearNewItemsOnHeaderClick:SetChecked(addon.GetClearNewItemsOnHeaderClick and addon.GetClearNewItemsOnHeaderClick() or false)
		page.ClearNewItemsOnHeaderClick:SetEnabled(not oneBagMode)
		page.ClearNewItemsOnHeaderClick:SetAlpha(oneBagMode and 0.45 or 1)
		if page.ClearNewItemsOnHeaderClick.Label then
			page.ClearNewItemsOnHeaderClick.Label:SetAlpha(oneBagMode and 0.45 or 1)
		end
	end
	if page.CategoryTreeView then
		page.CategoryTreeView:SetChecked(addon.GetCategoryTreeView and addon.GetCategoryTreeView() or false)
		page.CategoryTreeView:SetEnabled(not oneBagMode)
		page.CategoryTreeView:SetAlpha(oneBagMode and 0.45 or 1)
		if page.CategoryTreeView.Label then
			page.CategoryTreeView.Label:SetAlpha(oneBagMode and 0.45 or 1)
		end
	end
	if page.CompactCategoryLayout then
		local compactLayoutEnabled = addon.GetCompactCategoryLayout and addon.GetCompactCategoryLayout() or settings.compactCategoryLayout == true
		local categoryOptionsEnabled = settings.showCategories and not oneBagMode
		page.CompactCategoryLayout:SetChecked(compactLayoutEnabled)
		page.CompactCategoryLayout:SetEnabled(categoryOptionsEnabled)
		page.CompactCategoryLayout:SetAlpha(categoryOptionsEnabled and 1 or 0.45)
		if page.CompactCategoryLayout.Label then
			page.CompactCategoryLayout.Label:SetAlpha(categoryOptionsEnabled and 1 or 0.45)
		end
		if page.CompactCategoryGapControl and page.CompactCategoryGapControl.Value then
			local compactGap = addon.GetCompactCategoryGap and addon.GetCompactCategoryGap() or 8
			local gapEnabled = categoryOptionsEnabled and compactLayoutEnabled
			page.CompactCategoryGapControl.Row:SetAlpha(gapEnabled and 1 or 0.45)
			page.CompactCategoryGapControl.Value:SetText(tostring(compactGap))
			page.CompactCategoryGapControl.DownButton:SetEnabled(gapEnabled and compactGap > 0)
			page.CompactCategoryGapControl.UpButton:SetEnabled(gapEnabled and compactGap < 40)
		end
	end
	if page.CategoryTreeIndentControl and page.CategoryTreeIndentControl.Value then
		local treeViewEnabled = addon.GetCategoryTreeView and addon.GetCategoryTreeView() or false
		local treeIndent = addon.GetCategoryTreeIndent and addon.GetCategoryTreeIndent() or 14
		treeViewEnabled = treeViewEnabled and not oneBagMode
		page.CategoryTreeIndentControl.Row:SetAlpha(treeViewEnabled and 1 or 0.45)
		page.CategoryTreeIndentControl.Value:SetText(tostring(treeIndent))
		page.CategoryTreeIndentControl.DownButton:SetEnabled(treeViewEnabled and treeIndent > 0)
		page.CategoryTreeIndentControl.UpButton:SetEnabled(treeViewEnabled and treeIndent < 40)
	end
	if page.ShowCloseButton then
		page.ShowCloseButton:SetChecked(addon.GetShowCloseButton == nil or addon.GetShowCloseButton())
	end
	if page.RememberLastBankTab then
		page.RememberLastBankTab:SetChecked(addon.GetRememberLastBankTab == nil or addon.GetRememberLastBankTab())
	end
	if page.UseIntegratedBank then
		page.UseIntegratedBank:SetChecked(addon.GetUseIntegratedBank == nil or addon.GetUseIntegratedBank())
	end
	if page.OutsideHeaderPaddingControl and page.OutsideHeaderPaddingControl.Value then
		local outsideHeaderPadding = addon.GetOutsideHeaderPadding and addon.GetOutsideHeaderPadding() or 0
		page.OutsideHeaderPaddingControl.Value:SetText(tostring(outsideHeaderPadding))
		page.OutsideHeaderPaddingControl.DownButton:SetEnabled(outsideHeaderPadding > 0)
		page.OutsideHeaderPaddingControl.UpButton:SetEnabled(outsideHeaderPadding < 24)
	end
	if page.OutsideFooterPaddingControl and page.OutsideFooterPaddingControl.Value then
		local outsideFooterPadding = addon.GetOutsideFooterPadding and addon.GetOutsideFooterPadding() or 10
		page.OutsideFooterPaddingControl.Value:SetText(tostring(outsideFooterPadding))
		page.OutsideFooterPaddingControl.DownButton:SetEnabled(outsideFooterPadding > 0)
		page.OutsideFooterPaddingControl.UpButton:SetEnabled(outsideFooterPadding < 24)
	end
	if page.InsideHorizontalPaddingControl and page.InsideHorizontalPaddingControl.Value then
		local insideHorizontalPadding = addon.GetInsideHorizontalPadding and addon.GetInsideHorizontalPadding() or 10
		page.InsideHorizontalPaddingControl.Value:SetText(tostring(insideHorizontalPadding))
		page.InsideHorizontalPaddingControl.DownButton:SetEnabled(insideHorizontalPadding > 0)
		page.InsideHorizontalPaddingControl.UpButton:SetEnabled(insideHorizontalPadding < 24)
	end
	if page.InsideTopPaddingControl and page.InsideTopPaddingControl.Value then
		local insideTopPadding = addon.GetInsideTopPadding and addon.GetInsideTopPadding() or 10
		page.InsideTopPaddingControl.Value:SetText(tostring(insideTopPadding))
		page.InsideTopPaddingControl.DownButton:SetEnabled(insideTopPadding > 0)
		page.InsideTopPaddingControl.UpButton:SetEnabled(insideTopPadding < 24)
	end
	if page.InsideBottomPaddingControl and page.InsideBottomPaddingControl.Value then
		local insideBottomPadding = addon.GetInsideBottomPadding and addon.GetInsideBottomPadding() or 0
		page.InsideBottomPaddingControl.Value:SetText(tostring(insideBottomPadding))
		page.InsideBottomPaddingControl.DownButton:SetEnabled(insideBottomPadding > 0)
		page.InsideBottomPaddingControl.UpButton:SetEnabled(insideBottomPadding < 24)
	end
	if page.ItemScaleControl and page.ItemScaleControl.Value then
		local itemScale = addon.GetItemScale and addon.GetItemScale() or 100
		page.ItemScaleControl.Value:SetText(string.format("%d%%", itemScale))
		page.ItemScaleControl.DownButton:SetEnabled(itemScale > 80)
		page.ItemScaleControl.UpButton:SetEnabled(itemScale < 160)
	end
	if page.MaxColumnsControl and page.MaxColumnsControl.Value then
		local maxColumns = addon.GetMaxColumns and addon.GetMaxColumns() or 10
		page.MaxColumnsControl.Value:SetText(tostring(maxColumns))
		page.MaxColumnsControl.DownButton:SetEnabled(maxColumns > 4)
		page.MaxColumnsControl.UpButton:SetEnabled(maxColumns < 24)
	end
	if page.TextFontButton then
		page.TextFontButton:SetText(getOptionLabel(addon.GetTextFontOptions and addon.GetTextFontOptions() or {}, appearance.font, L["settingsTextFontLabel"] or "Font"))
	end
	if page.SkinPresetButton then
		page.SkinPresetButton:SetText(getOptionLabel(addon.GetSkinPresetOptions and addon.GetSkinPresetOptions() or {}, addon.GetSkinPreset and addon.GetSkinPreset() or "default", L["settingsSkinPresetLabel"] or "Skin"))
	end
	if page.IconShapeButton then
		page.IconShapeButton:SetText(getOptionLabel(addon.GetIconShapeOptions and addon.GetIconShapeOptions() or {}, addon.GetIconShape and addon.GetIconShape() or "preset", L["settingsIconShapeLabel"] or "Icon shape"))
	end
	if page.FreeSlotDisplayButton then
		local mode = addon.GetFreeSlotDisplayMode and addon.GetFreeSlotDisplayMode() or "icons"
		page.FreeSlotDisplayButton:SetText(getOptionLabel(addon.GetFreeSlotDisplayModeOptions and addon.GetFreeSlotDisplayModeOptions() or {}, mode, mode))
	end
	local colorModeEnabled = addon.GetFreeSlotDisplayMode and addon.GetFreeSlotDisplayMode() == "colors"
	if page.FreeSlotNormalColorSwatch then
		local color = addon.GetFreeSlotColor and addon.GetFreeSlotColor("normal") or { 0.18, 0.12, 0.06 }
		page.FreeSlotNormalColorSwatch:SetColorRGB(color[1] or 1, color[2] or 1, color[3] or 1)
		page.FreeSlotNormalColorSwatch:SetEnabled(colorModeEnabled)
		page.FreeSlotNormalColorSwatch:SetAlpha(colorModeEnabled and 1 or 0.45)
	end
	if page.FreeSlotReagentColorSwatch then
		local color = addon.GetFreeSlotColor and addon.GetFreeSlotColor("reagent") or { 0.36, 0.27, 0.08 }
		page.FreeSlotReagentColorSwatch:SetColorRGB(color[1] or 1, color[2] or 1, color[3] or 1)
		page.FreeSlotReagentColorSwatch:SetEnabled(colorModeEnabled)
		page.FreeSlotReagentColorSwatch:SetAlpha(colorModeEnabled and 1 or 0.45)
	end
	if page.FreeSlotNormalColorLabel then
		page.FreeSlotNormalColorLabel:SetAlpha(colorModeEnabled and 1 or 0.5)
	end
	if page.FreeSlotReagentColorLabel then
		page.FreeSlotReagentColorLabel:SetAlpha(colorModeEnabled and 1 or 0.5)
	end
	if page.FrameBackgroundButton then
		page.FrameBackgroundButton:SetText(getOptionLabel(addon.GetFrameBackgroundOptions and addon.GetFrameBackgroundOptions() or {}, addon.GetFrameBackground and addon.GetFrameBackground() or "solid", L["settingsFrameBackgroundLabel"] or "Background"))
	end
	if page.FrameBackgroundColorSwatch then
		local color = addon.GetFrameBackgroundColor and addon.GetFrameBackgroundColor() or { 0.03, 0.03, 0.04 }
		local isSolidBackground = (addon.GetFrameBackground and addon.GetFrameBackground() or "solid") == "solid"
		page.FrameBackgroundColorSwatch:SetColorRGB(color[1] or 0.03, color[2] or 0.03, color[3] or 0.04)
		page.FrameBackgroundColorSwatch:SetEnabled(isSolidBackground)
		page.FrameBackgroundColorSwatch:SetAlpha(isSolidBackground and 1 or 0.45)
		page.FrameBackgroundColorLabel:SetAlpha(isSolidBackground and 1 or 0.45)
	end
	if page.FrameBackgroundOpacityValue then
		local backgroundOpacity = addon.GetFrameBackgroundOpacity and addon.GetFrameBackgroundOpacity() or 60
		page.FrameBackgroundOpacityValue:SetText(string.format("%d%%", backgroundOpacity))
		page.FrameBackgroundOpacityDownButton:SetEnabled(backgroundOpacity > 0)
		page.FrameBackgroundOpacityUpButton:SetEnabled(backgroundOpacity < 100)
	end
	if page.FrameBorderTextureButton then
		page.FrameBorderTextureButton:SetText(getOptionLabel(addon.GetFrameBorderTextureOptions and addon.GetFrameBorderTextureOptions() or {}, addon.GetFrameBorderTexture and addon.GetFrameBorderTexture() or "__skin__", L["settingsFrameBorderTextureLabel"] or "Border texture"))
	end
	if page.FrameBorderColorSwatch then
		local skin = addon.GetActiveSkinDefinition and addon.GetActiveSkinDefinition() or nil
		local color = addon.GetFrameBorderColor and addon.GetFrameBorderColor(skin and skin.frame and skin.frame.borderColor) or { 0.35, 0.35, 0.42, 1 }
		page.FrameBorderColorSwatch:SetColorRGB(color[1] or 0.35, color[2] or 0.35, color[3] or 0.42)
	end
	if page.FrameBorderColorLabel then
		page.FrameBorderColorLabel:SetAlpha((addon.HasCustomFrameBorderColor and addon.HasCustomFrameBorderColor()) and 1 or 0.78)
	end
	if page.FrameBorderSizeValue then
		local borderSize = addon.GetFrameBorderSize and addon.GetFrameBorderSize() or 1
		page.FrameBorderSizeValue:SetText(tostring(borderSize))
		page.FrameBorderSizeDownButton:SetEnabled(borderSize > 0)
		page.FrameBorderSizeUpButton:SetEnabled(borderSize < 64)
	end
	if page.FrameBorderOffsetValue then
		local borderOffset = addon.GetFrameBorderOffset and addon.GetFrameBorderOffset() or 0
		page.FrameBorderOffsetValue:SetText(tostring(borderOffset))
		page.FrameBorderOffsetDownButton:SetEnabled(borderOffset > -32)
		page.FrameBorderOffsetUpButton:SetEnabled(borderOffset < 32)
	end
	if page.TextSizeValue then
		page.TextSizeValue:SetText(tostring(tonumber(appearance.size) or 12))
	end
	if page.TextOverlaySizeValue then
		local overlaySize = addon.GetTextAppearanceOverlaySize and addon.GetTextAppearanceOverlaySize() or tonumber(appearance.overlaySize) or tonumber(appearance.size) or 12
		page.TextOverlaySizeValue:SetText(tostring(overlaySize))
	end
	if page.TextOutlineButton then
		page.TextOutlineButton:SetText(getOptionLabel(addon.GetTextOutlineOptions and addon.GetTextOutlineOptions() or {}, appearance.outline, L["settingsTextOutlineLabel"] or "Outline"))
	end
	for _, row in ipairs(page.TextStyleRows or {}) do
		local elementID = row.ElementID
		local elementAppearance = addon.GetTextElementAppearance and addon.GetTextElementAppearance(elementID) or {}
		local size = tonumber(elementAppearance.size) or 12
		if row.FontButton then
			row.FontButton:SetText(getOptionLabel(addon.GetTextElementFontOptions and addon.GetTextElementFontOptions() or {}, elementAppearance.font, L["settingsTextElementFontLabel"] or "Element font"))
		end
		if row.SizeValue then
			row.SizeValue:SetText(tostring(size))
		end
		if row.SizeDownButton then
			row.SizeDownButton:SetEnabled(size > 8)
		end
		if row.SizeUpButton then
			row.SizeUpButton:SetEnabled(size < 24)
		end
		if row.CaseButton then
			row.CaseButton:SetShown(elementID ~= "stackCount")
			row.CaseButton:SetText(getOptionLabel(addon.GetTextCaseOptions and addon.GetTextCaseOptions() or {}, elementAppearance.case or "default", L["settingsTextCaseLabel"] or "Case"))
		end
		if row.StackAnchorButton then
			row.StackAnchorButton:SetShown(elementID == "stackCount")
			row.StackAnchorButton:SetText(getOptionLabel(
				addon.GetStackCountAnchorOptions and addon.GetStackCountAnchorOptions() or {},
				addon.GetStackCountAnchor and addon.GetStackCountAnchor() or "BOTTOMRIGHT",
				L["settingsOverlayAnchorLabel"] or "Anchor"
			))
		end
		if row.OutlineButton then
			row.OutlineButton:SetText(getOptionLabel(addon.GetTextElementOutlineOptions and addon.GetTextElementOutlineOptions() or {}, elementAppearance.outline, L["settingsTextElementOutlineLabel"] or "Element outline"))
		end
	end
	if page.SubcategoryFullLabels then
		page.SubcategoryFullLabels:SetChecked(addon.GetSubcategoryFullLabels and addon.GetSubcategoryFullLabels() or false)
	end
	if page.TextPreview and addon.ApplyConfiguredFont then
		addon.ApplyConfiguredFont(page.TextPreview, nil, "categoryHeader")
		page.TextPreview:SetText(addon.FormatTextElement and addon.FormatTextElement("categoryHeader", L["simpleBagsTitle"] or "Bags") or L["simpleBagsTitle"] or "Bags")
		local skin = addon.GetActiveSkinDefinition and addon.GetActiveSkinDefinition() or nil
		local titleColor = skin and skin.frame and skin.frame.titleColor or nil
		page.TextPreview:SetTextColor(titleColor and titleColor[1] or 1, titleColor and titleColor[2] or 0.82, titleColor and titleColor[3] or 0.16)
	end
	if page.TextOverlayPreview and addon.ApplyConfiguredFont then
		addon.ApplyConfiguredFont(page.TextOverlayPreview, nil, "overlays")
		page.TextOverlayPreview:SetTextColor(0.8, 0.34, 1)
	end
	if page.ScrollFrame and page.Content and page.LayoutContentHeight then
		updateScrollContainer(page.ScrollFrame, page.Content, page.LayoutContentHeight)
	end
end

local function createFooterPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints()

	createPageHeader(
		page,
		L["settingsCategoryFooter"] or "Footer",
		L["settingsFooterDescription"] or "Gold, currency and slot summary controls."
	)

	page.ShowGold = createCheckbox(
		page,
		L["settingsShowGold"] or "Show gold",
		L["settingsShowGoldTooltip"] or "",
		0,
		-68,
		function(value)
			getSettings().showGold = value
			requestBagRefresh(false)
		end
	)

	local moneyFormatLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	moneyFormatLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 28, -102)
	moneyFormatLabel:SetPoint("RIGHT", page, "RIGHT", -184, 0)
	moneyFormatLabel:SetJustifyH("LEFT")
	moneyFormatLabel:SetText(L["settingsMoneyFormatLabel"] or "Money format")
	page.MoneyFormatLabel = moneyFormatLabel

	local moneyFormatButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
	moneyFormatButton:SetSize(156, 22)
	moneyFormatButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -14, -98)
	setButtonFontObject(moneyFormatButton, GameFontNormalSmall)
	moneyFormatButton:SetScript("OnClick", function(self)
		local moneyFormat = addon.GetMoneyFormat and addon.GetMoneyFormat() or "symbols"
		openSimpleRadioMenu(self, addon.GetMoneyFormatOptions and addon.GetMoneyFormatOptions() or {}, moneyFormat, function(value)
			if addon.SetMoneyFormat and addon.SetMoneyFormat(value) then
				addon.RefreshSettingsFrame("footer")
				requestBagRefresh(true)
			end
		end)
	end)
	page.MoneyFormatButton = moneyFormatButton

	page.ShowCurrencies = createCheckbox(
		page,
		L["settingsShowCurrencies"] or "Show currencies",
		L["settingsShowCurrenciesTooltip"] or "",
		0,
		-132,
		function(value)
			getSettings().showCurrencies = value
			requestBagRefresh(false)
		end
	)

	page.ShowFooterSlotSummary = createCheckbox(
		page,
		L["settingsShowFooterSlotSummary"] or "Show free slot summary",
		L["settingsShowFooterSlotSummaryTooltip"] or "",
		0,
		-162,
		function(value)
			getSettings().showFooterSlotSummary = value
			addon.RefreshSettingsFrame("layout")
			requestBagRefresh(false)
		end
	)

	local trackedCard = CreateFrame("Frame", nil, page, "BackdropTemplate")
	trackedCard:SetPoint("TOPLEFT", page.ShowFooterSlotSummary, "BOTTOMLEFT", 0, -28)
	trackedCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -8, 0)
	createCardBackdrop(trackedCard)
	page.TrackedCharactersCard = trackedCard

	local trackedTitle = trackedCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	trackedTitle:SetPoint("TOPLEFT", trackedCard, "TOPLEFT", 14, -14)
	trackedTitle:SetText(L["settingsTrackedCharacters"] or "Tracked characters")
	page.TrackedCharactersTitle = trackedTitle

	local trackedHint = trackedCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	trackedHint:SetPoint("TOPLEFT", trackedTitle, "BOTTOMLEFT", 0, -4)
	trackedHint:SetPoint("RIGHT", trackedCard, "RIGHT", -14, 0)
	trackedHint:SetJustifyH("LEFT")
	trackedHint:SetJustifyV("TOP")
	trackedHint:SetText(L["settingsTrackedCharactersHint"] or "")
	page.TrackedCharactersHint = trackedHint

	local scrollFrame, content = createScrollContainer(trackedCard, SETTINGS_FOOTER_TRACKED_SCROLLFRAME_NAME)
	scrollFrame:SetPoint("TOPLEFT", trackedHint, "BOTTOMLEFT", -2, -10)
	scrollFrame:SetPoint("BOTTOMRIGHT", trackedCard, "BOTTOMRIGHT", -28, 12)
	page.CharacterListScrollFrame = scrollFrame
	page.CharacterListContent = content
	page.CharacterRows = {}

	local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	emptyText:SetPoint("TOPLEFT", content, "TOPLEFT", 12, -12)
	emptyText:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -12, 12)
	emptyText:SetJustifyH("CENTER")
	emptyText:SetJustifyV("MIDDLE")
	emptyText:SetText(L["settingsTrackedCharactersEmpty"] or "No tracked characters yet.")
	page.EmptyTrackedCharactersText = emptyText

	return page
end

local function createTrackingPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints()

	createPageHeader(
		page,
		L["settingsCategoryTracking"] or "Tracking",
		L["settingsTrackingDescription"] or "Use watched backpack currencies and optional currency IDs."
	)

	local scrollFrame, content = createScrollContainer(page, SETTINGS_TRACKING_SCROLLFRAME_NAME)
	scrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -74)
	scrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 0)
	page.ScrollFrame = scrollFrame
	page.Content = content

	page.ShowWatchedCurrencies = createCheckbox(
		content,
		L["settingsUseWatchedCurrencies"] or "Use watched backpack currencies",
		L["settingsUseWatchedCurrenciesTooltip"] or "",
		0,
		-8,
		function(value)
			getSettings().showWatchedCurrencies = value
			requestBagRefresh(false)
		end
	)

	page.ShowTrackedCurrencyCharacterBreakdown = createCheckbox(
		content,
		L["settingsShowTrackedCurrencyCharacterBreakdown"] or "Show warband character currencies in tooltip",
		L["settingsShowTrackedCurrencyCharacterBreakdownTooltip"] or "",
		0,
		-38,
		function(value)
			if addon.SetShowTrackedCurrencyCharacterBreakdown then
				addon.SetShowTrackedCurrencyCharacterBreakdown(value)
			else
				getSettings().showTrackedCurrencyCharacterBreakdown = value
			end
			if value and addon.RequestTrackedCurrencyCharacterData then
				addon.RequestTrackedCurrencyCharacterData(true)
			end
			addon.RefreshSettingsFrame("tracking")
			requestBagRefresh(false)
		end
	)

	local tooltipCard = CreateFrame("Frame", nil, content, "BackdropTemplate")
	tooltipCard:SetPoint("TOPLEFT", page.ShowTrackedCurrencyCharacterBreakdown, "BOTTOMLEFT", 0, -24)
	tooltipCard:SetPoint("RIGHT", content, "RIGHT", -8, 0)
	tooltipCard:SetHeight(154)
	createCardBackdrop(tooltipCard)
	page.TrackedCurrencyTooltipCard = tooltipCard

	local tooltipTitle = tooltipCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tooltipTitle:SetPoint("TOPLEFT", tooltipCard, "TOPLEFT", 14, -14)
	tooltipTitle:SetText(L["settingsTrackedCurrencyTooltipTitle"] or "Tooltip display")
	page.TrackedCurrencyTooltipTitle = tooltipTitle

	local tooltipHint = tooltipCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tooltipHint:SetPoint("TOPLEFT", tooltipTitle, "BOTTOMLEFT", 0, -4)
	tooltipHint:SetPoint("RIGHT", tooltipCard, "RIGHT", -14, 0)
	tooltipHint:SetJustifyH("LEFT")
	tooltipHint:SetJustifyV("TOP")
	tooltipHint:SetText(L["settingsTrackedCurrencyTooltipHint"] or "")
	page.TrackedCurrencyTooltipHint = tooltipHint

	local totalPositionLabel = tooltipCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	totalPositionLabel:SetPoint("TOPLEFT", tooltipHint, "BOTTOMLEFT", 0, -16)
	totalPositionLabel:SetPoint("RIGHT", tooltipCard, "RIGHT", -184, 0)
	totalPositionLabel:SetJustifyH("LEFT")
	totalPositionLabel:SetText(L["settingsTrackedCurrencyTooltipTotalPositionLabel"] or "Total position")
	page.TrackedCurrencyTooltipTotalPositionLabel = totalPositionLabel

	local totalPositionButton = CreateFrame("Button", nil, tooltipCard, "UIPanelButtonTemplate")
	totalPositionButton:SetSize(156, 22)
	totalPositionButton:SetPoint("TOPRIGHT", tooltipCard, "TOPRIGHT", -14, -52)
	setButtonFontObject(totalPositionButton, GameFontNormalSmall)
	totalPositionButton:SetScript("OnClick", function(self)
		openSimpleRadioMenu(self, addon.GetTrackedCurrencyTooltipTotalPositionOptions and addon.GetTrackedCurrencyTooltipTotalPositionOptions() or {}, addon.GetTrackedCurrencyTooltipTotalPosition and addon.GetTrackedCurrencyTooltipTotalPosition() or "top", function(value)
			if addon.SetTrackedCurrencyTooltipTotalPosition and addon.SetTrackedCurrencyTooltipTotalPosition(value) then
				addon.RefreshSettingsFrame("tracking")
				requestBagRefresh(false)
			end
		end)
	end)
	page.TrackedCurrencyTooltipTotalPositionButton = totalPositionButton

	local nameColorLabel = tooltipCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameColorLabel:SetPoint("TOPLEFT", totalPositionLabel, "BOTTOMLEFT", 0, -18)
	nameColorLabel:SetPoint("RIGHT", tooltipCard, "RIGHT", -184, 0)
	nameColorLabel:SetJustifyH("LEFT")
	nameColorLabel:SetText(L["settingsTrackedCurrencyTooltipNameColorLabel"] or "Name color")
	page.TrackedCurrencyTooltipNameColorLabel = nameColorLabel

	local nameColorButton = CreateFrame("Button", nil, tooltipCard, "UIPanelButtonTemplate")
	nameColorButton:SetSize(156, 22)
	nameColorButton:SetPoint("TOPRIGHT", totalPositionButton, "BOTTOMRIGHT", 0, -14)
	setButtonFontObject(nameColorButton, GameFontNormalSmall)
	nameColorButton:SetScript("OnClick", function(self)
		openSimpleRadioMenu(self, addon.GetTrackedCurrencyTooltipColorModeOptions and addon.GetTrackedCurrencyTooltipColorModeOptions() or {}, addon.GetTrackedCurrencyTooltipNameColorMode and addon.GetTrackedCurrencyTooltipNameColorMode() or "default", function(value)
			if addon.SetTrackedCurrencyTooltipNameColorMode and addon.SetTrackedCurrencyTooltipNameColorMode(value) then
				addon.RefreshSettingsFrame("tracking")
				requestBagRefresh(false)
			end
		end)
	end)
	page.TrackedCurrencyTooltipNameColorButton = nameColorButton

	local countColorLabel = tooltipCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	countColorLabel:SetPoint("TOPLEFT", nameColorLabel, "BOTTOMLEFT", 0, -18)
	countColorLabel:SetPoint("RIGHT", tooltipCard, "RIGHT", -184, 0)
	countColorLabel:SetJustifyH("LEFT")
	countColorLabel:SetText(L["settingsTrackedCurrencyTooltipCountColorLabel"] or "Count color")
	page.TrackedCurrencyTooltipCountColorLabel = countColorLabel

	local countColorButton = CreateFrame("Button", nil, tooltipCard, "UIPanelButtonTemplate")
	countColorButton:SetSize(156, 22)
	countColorButton:SetPoint("TOPRIGHT", nameColorButton, "BOTTOMRIGHT", 0, -14)
	setButtonFontObject(countColorButton, GameFontNormalSmall)
	countColorButton:SetScript("OnClick", function(self)
		openSimpleRadioMenu(self, addon.GetTrackedCurrencyTooltipColorModeOptions and addon.GetTrackedCurrencyTooltipColorModeOptions() or {}, addon.GetTrackedCurrencyTooltipCountColorMode and addon.GetTrackedCurrencyTooltipCountColorMode() or "default", function(value)
			if addon.SetTrackedCurrencyTooltipCountColorMode and addon.SetTrackedCurrencyTooltipCountColorMode(value) then
				addon.RefreshSettingsFrame("tracking")
				requestBagRefresh(false)
			end
		end)
	end)
	page.TrackedCurrencyTooltipCountColorButton = countColorButton

	local trackedCard = CreateFrame("Frame", nil, content, "BackdropTemplate")
	trackedCard:SetPoint("TOPLEFT", tooltipCard, "BOTTOMLEFT", 0, -18)
	trackedCard:SetPoint("RIGHT", content, "RIGHT", -8, 0)
	trackedCard:SetHeight(274)
	createCardBackdrop(trackedCard)
	page.TrackedCurrencyCard = trackedCard

	local trackedTitle = trackedCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	trackedTitle:SetPoint("TOPLEFT", trackedCard, "TOPLEFT", 14, -14)
	trackedTitle:SetText(L["settingsTrackedCurrencies"] or "Tracked currencies")
	page.TrackedCurrencyTitle = trackedTitle

	local trackedHint = trackedCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	trackedHint:SetPoint("TOPLEFT", trackedTitle, "BOTTOMLEFT", 0, -4)
	trackedHint:SetPoint("RIGHT", trackedCard, "RIGHT", -14, 0)
	trackedHint:SetJustifyH("LEFT")
	trackedHint:SetJustifyV("TOP")
	trackedHint:SetText(L["settingsTrackedCurrenciesHint"] or "")
	page.TrackedCurrencyHint = trackedHint

	local addBox = CreateFrame("EditBox", nil, trackedCard, "InputBoxTemplate")
	addBox:SetSize(110, 24)
	addBox:SetPoint("TOPLEFT", trackedHint, "BOTTOMLEFT", 0, -16)
	addBox:SetAutoFocus(false)
	addBox:SetNumeric(true)
	addBox:SetMaxLetters(7)
	addBox:SetScript("OnEnterPressed", function(self)
		tryAddTrackedCurrencyFromPage(page)
		self:ClearFocus()
	end)
	page.TrackedCurrencyAddBox = addBox
	attachEditBoxPlaceholder(addBox, L["settingsTrackedCurrencyAddPlaceholder"] or "Currency ID")

	local addButton = CreateFrame("Button", nil, trackedCard, "UIPanelButtonTemplate")
	addButton:SetSize(58, 24)
	addButton:SetPoint("LEFT", addBox, "RIGHT", 8, 0)
	addButton:SetText(ADD)
	setButtonFontObject(addButton, GameFontNormalSmall)
	addButton:SetScript("OnClick", function()
		tryAddTrackedCurrencyFromPage(page)
	end)
	page.TrackedCurrencyAddButton = addButton

	local statusText = trackedCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	statusText:SetPoint("LEFT", addButton, "RIGHT", 10, 0)
	statusText:SetPoint("RIGHT", trackedCard, "RIGHT", -14, 0)
	statusText:SetJustifyH("LEFT")
	setSingleLineText(statusText)
	page.TrackedCurrencyStatus = statusText

	local currencyScrollFrame, currencyContent = createScrollContainer(trackedCard, SETTINGS_TRACKED_CURRENCY_SCROLLFRAME_NAME)
	currencyScrollFrame:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", -2, -12)
	currencyScrollFrame:SetPoint("BOTTOMRIGHT", trackedCard, "BOTTOMRIGHT", -28, 12)
	page.TrackedCurrencyScrollFrame = currencyScrollFrame
	page.TrackedCurrencyListContent = currencyContent
	page.TrackedCurrencyRows = {}

	local emptyText = currencyContent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	emptyText:SetPoint("TOPLEFT", currencyContent, "TOPLEFT", 12, -12)
	emptyText:SetPoint("BOTTOMRIGHT", currencyContent, "BOTTOMRIGHT", -12, 12)
	emptyText:SetJustifyH("CENTER")
	emptyText:SetJustifyV("MIDDLE")
	emptyText:SetText(L["settingsTrackedCurrenciesEmpty"] or "No tracked currencies yet.")
	page.EmptyTrackedCurrenciesText = emptyText

	page.TrackingContentHeight = 528
	updateScrollContainer(scrollFrame, content, page.TrackingContentHeight)

	return page
end

local function createOverlaysPage(parent)
	local page = CreateFrame("Frame", nil, parent)
	page:SetAllPoints()

	createPageHeader(
		page,
		L["settingsCategoryOverlays"] or "Overlays",
		L["settingsOverlaysDescription"] or "Position item overlays like item level directly on the slot."
	)

	local scrollFrame, content = createScrollContainer(page, SETTINGS_OVERLAY_SCROLLFRAME_NAME)
	scrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -74)
	scrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 0)
	page.ScrollFrame = scrollFrame
	page.Content = content

	page.ShowCraftedQuality = createInlineCheckbox(
		content,
		L["settingsShowCraftedQuality"] or "Show crafted quality",
		L["settingsShowCraftedQualityTooltip"] or "Shows Blizzard's crafted quality icon on crafted equipment when available.",
		function(value)
			if addon.SetShowCraftedQuality then
				addon.SetShowCraftedQuality(value)
			else
				getSettings().showCraftedQuality = value == true
			end
			requestBagRefresh(false, true)
		end
	)
	page.ShowCraftedQuality:SetPoint("TOPLEFT", content, "TOPLEFT", 4, 0)
	page.ShowCraftedQuality:SetChecked(addon.GetShowCraftedQuality and addon.GetShowCraftedQuality() or getSettings().showCraftedQuality == true)

	page.Cards = {}
	local previousCard
	for index, definition in ipairs(getOverlayElements()) do
		local card = createOverlayAnchorCard(content, definition)
		if index == 1 then
			card:SetPoint("TOPLEFT", page.ShowCraftedQuality, "BOTTOMLEFT", -4, -12)
		else
			card:SetPoint("TOPLEFT", previousCard, "BOTTOMLEFT", 0, -12)
		end
		card:SetPoint("RIGHT", content, "RIGHT", -6, 0)
		page.Cards[#page.Cards + 1] = card
		previousCard = card
	end

	local contentHeight = 1
	if previousCard then
		contentHeight = 46
		for _, card in ipairs(page.Cards) do
			updateOverlayCardLayout(card)
			contentHeight = contentHeight + card:GetHeight() + 12
		end
	end
	updateScrollContainer(scrollFrame, content, contentHeight)

	return page
end

refreshOverlaysPage = function(page)
	if not page then
		return
	end

	if page.ShowCraftedQuality then
		page.ShowCraftedQuality:SetChecked(addon.GetShowCraftedQuality and addon.GetShowCraftedQuality() or getSettings().showCraftedQuality == true)
	end

	local contentHeight = 1
	if #(page.Cards or {}) > 0 then
		contentHeight = 46
		for _, card in ipairs(page.Cards or {}) do
			updateOverlayCardLayout(card)
			refreshOverlayCard(card)
			contentHeight = contentHeight + card:GetHeight() + 12
		end
	end

	updateScrollContainer(page.ScrollFrame, page.Content, contentHeight)
end

local function anchorPaddingControl(card, control, topOffset)
	if not card or not control or not control.Label or not control.Stepper then
		return
	end

	control.Label:ClearAllPoints()
	control.Label:SetPoint("TOPLEFT", card, "TOPLEFT", 14, topOffset)
	control.Label:SetPoint("RIGHT", card, "RIGHT", -184, 0)
	control.Label:SetJustifyH("LEFT")

	control.Stepper:ClearAllPoints()
	control.Stepper:SetSize(156, 22)
	control.Stepper:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, topOffset + 4)
end

local function anchorTextAppearanceControl(card, hint, label, control, previousControl)
	if not card or not hint or not label or not control then
		return
	end

	control:ClearAllPoints()
	if previousControl then
		control:SetPoint("TOPRIGHT", previousControl, "BOTTOMRIGHT", 0, -12)
	else
		control:SetPoint("TOPRIGHT", hint, "BOTTOMRIGHT", 0, -16)
	end

	label:ClearAllPoints()
	label:SetPoint("LEFT", card, "LEFT", 14, 0)
	label:SetPoint("RIGHT", control, "LEFT", -16, 0)
	label:SetPoint("TOP", control, "TOP", 0, 0)
	label:SetPoint("BOTTOM", control, "BOTTOM", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetJustifyV("MIDDLE")
end

local function setLayoutCheckboxVisible(button, visible)
	if not button then
		return
	end
	button:SetShown(visible)
	if button.Label then
		button.Label:SetShown(visible)
	end
end

applyLayoutPageMode = function(page)
	if not page then
		return
	end

	local basicMode = isBasicCategoryMode()
	local oneBagMode = isOneBagModeEnabled()
	local previousControl
	local function placeLayoutCheckbox(button, visible)
		setLayoutCheckboxVisible(button, visible)
		if not visible or not button then
			return
		end

		button:ClearAllPoints()
		if previousControl then
			button:SetPoint("TOPLEFT", previousControl, "BOTTOMLEFT", 0, -8)
		else
			button:SetPoint("TOPLEFT", page.Content, "TOPLEFT", 0, -8)
		end
		previousControl = button
	end

	placeLayoutCheckbox(page.OneBagMode, true)
	placeLayoutCheckbox(page.OneBagFreeSlotsAtEnd, oneBagMode)
	placeLayoutCheckbox(page.ShowCategories, not basicMode and not oneBagMode)
	placeLayoutCheckbox(page.CombineFreeSlots, not oneBagMode)
	placeLayoutCheckbox(page.ShowFreeSlots, true)
	placeLayoutCheckbox(page.CombineDuplicateItems, not oneBagMode)
	placeLayoutCheckbox(page.ClearNewItemsOnHeaderClick, not oneBagMode)
	placeLayoutCheckbox(page.CompactCategoryLayout, not oneBagMode)
	placeLayoutCheckbox(page.CategoryTreeView, not oneBagMode)
	placeLayoutCheckbox(page.ShowCloseButton, true)
	placeLayoutCheckbox(page.RememberLastBankTab, true)
	placeLayoutCheckbox(page.UseIntegratedBank, true)

	if page.CompactCategoryGapControl and page.CompactCategoryGapControl.Row then
		page.CompactCategoryGapControl.Row:SetShown(not oneBagMode)
		if not oneBagMode then
			page.CompactCategoryGapControl.Row:ClearAllPoints()
			page.CompactCategoryGapControl.Row:SetPoint("TOPLEFT", previousControl, "BOTTOMLEFT", 24, -14)
			page.CompactCategoryGapControl.Row:SetPoint("RIGHT", page.Content, "RIGHT", -14, 0)
			previousControl = page.CompactCategoryGapControl.Row
		end
	end
	if page.CategoryTreeIndentControl and page.CategoryTreeIndentControl.Row then
		page.CategoryTreeIndentControl.Row:SetShown(not oneBagMode)
		if not oneBagMode then
			page.CategoryTreeIndentControl.Row:ClearAllPoints()
			page.CategoryTreeIndentControl.Row:SetPoint("TOPLEFT", previousControl, "BOTTOMLEFT", 0, -10)
			page.CategoryTreeIndentControl.Row:SetPoint("RIGHT", page.Content, "RIGHT", -14, 0)
			previousControl = page.CategoryTreeIndentControl.Row
		end
	end
	if page.ResetButton and previousControl then
		page.ResetButton:ClearAllPoints()
		local resetOffsetX = (previousControl == (page.CompactCategoryGapControl and page.CompactCategoryGapControl.Row)
			or previousControl == (page.CategoryTreeIndentControl and page.CategoryTreeIndentControl.Row)) and -20 or 4
		page.ResetButton:SetPoint("TOPLEFT", previousControl, "BOTTOMLEFT", resetOffsetX, -18)
	end
	if page.PaddingCard and page.ResetButton then
		page.PaddingCard:ClearAllPoints()
		page.PaddingCard:SetPoint("TOPLEFT", page.ResetButton, "BOTTOMLEFT", -4, -18)
		page.PaddingCard:SetPoint("RIGHT", page.Content, "RIGHT", -12, 0)
	end

	if page.PaddingCard then
		page.PaddingCard:SetHeight(basicMode and 122 or 258)
	end
	if page.PaddingTitle then
		page.PaddingTitle:SetText((basicMode and (L["settingsBasicLayoutTitle"] or "Item layout")) or (L["settingsPaddingTitle"] or "Padding"))
	end

	local hiddenPaddingControls = {
		page.OutsideHeaderPaddingControl,
		page.OutsideFooterPaddingControl,
		page.InsideHorizontalPaddingControl,
		page.InsideTopPaddingControl,
		page.InsideBottomPaddingControl,
	}
	for _, control in ipairs(hiddenPaddingControls) do
		if control then
			control.Label:SetShown(not basicMode)
			control.Stepper:SetShown(not basicMode)
		end
	end
	if page.ItemScaleControl then
		page.ItemScaleControl.Label:SetShown(true)
		page.ItemScaleControl.Stepper:SetShown(true)
		anchorPaddingControl(page.PaddingCard, page.ItemScaleControl, basicMode and -40 or -180)
	end
	if page.MaxColumnsControl then
		page.MaxColumnsControl.Label:SetShown(true)
		page.MaxColumnsControl.Stepper:SetShown(true)
		anchorPaddingControl(page.PaddingCard, page.MaxColumnsControl, basicMode and -68 or -208)
	end

	if page.TextAppearanceCard then
		page.TextAppearanceCard:SetHeight(basicMode and 664 or 948)
	end
	if page.TextAppearanceTitle then
		page.TextAppearanceTitle:SetText((basicMode and (L["settingsBasicLookTitle"] or "Look")) or (L["settingsTextAppearanceTitle"] or "Text appearance"))
	end
	if page.TextAppearanceHint then
		page.TextAppearanceHint:SetText(
			(basicMode and (L["settingsBasicLookHint"] or "Choose the bag skin, icon shape, background, border, opacity, font, sizes, and outline."))
				or (L["settingsTextAppearanceHint"] or "Choose the font, size, and outline used for bag headers, footer text, and item overlays.")
		)
	end

	for _, pair in ipairs({
		{ page.TextFontLabel, page.TextFontButton },
		{ page.TextSizeLabel, page.TextSizeStepper },
		{ page.TextOverlaySizeLabel, page.TextOverlaySizeStepper },
		{ page.TextOutlineLabel, page.TextOutlineButton },
	}) do
		if pair[1] then
			pair[1]:SetShown(true)
		end
		if pair[2] then
			pair[2]:SetShown(true)
		end
	end
	local showAdvancedLookControls = not basicMode
	if page.TextStylesTitle then
		page.TextStylesTitle:SetShown(showAdvancedLookControls)
	end
	for _, row in ipairs(page.TextStyleRows or {}) do
		row:SetShown(showAdvancedLookControls)
	end
	if page.TextPreviewLabel then
		page.TextPreviewLabel:SetShown(true)
	end
	if page.TextPreview then
		page.TextPreview:SetShown(true)
	end
	if page.TextOverlayPreview then
		page.TextOverlayPreview:SetShown(true)
	end
	if page.SubcategoryFullLabels then
		page.SubcategoryFullLabels:SetShown(showAdvancedLookControls)
		if page.SubcategoryFullLabels.Label then
			page.SubcategoryFullLabels.Label:SetShown(showAdvancedLookControls)
		end
	end

	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.SkinPresetLabel, page.SkinPresetButton)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.IconShapeLabel, page.IconShapeButton, page.SkinPresetButton)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FreeSlotDisplayLabel, page.FreeSlotDisplayButton, page.IconShapeButton)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FreeSlotNormalColorLabel, page.FreeSlotNormalColorSwatch, page.FreeSlotDisplayButton)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FreeSlotReagentColorLabel, page.FreeSlotReagentColorSwatch, page.FreeSlotNormalColorSwatch)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FrameBackgroundLabel, page.FrameBackgroundButton, page.FreeSlotReagentColorSwatch)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FrameBackgroundColorLabel, page.FrameBackgroundColorSwatch, page.FrameBackgroundButton)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FrameBackgroundOpacityLabel, page.FrameBackgroundOpacityStepper, page.FrameBackgroundColorSwatch)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FrameBorderTextureLabel, page.FrameBorderTextureButton, page.FrameBackgroundOpacityStepper)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FrameBorderColorLabel, page.FrameBorderColorSwatch, page.FrameBorderTextureButton)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FrameBorderSizeLabel, page.FrameBorderSizeStepper, page.FrameBorderColorSwatch)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.FrameBorderOffsetLabel, page.FrameBorderOffsetStepper, page.FrameBorderSizeStepper)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.TextFontLabel, page.TextFontButton, page.FrameBorderOffsetStepper)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.TextSizeLabel, page.TextSizeStepper, page.TextFontButton)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.TextOverlaySizeLabel, page.TextOverlaySizeStepper, page.TextSizeStepper)
	anchorTextAppearanceControl(page.TextAppearanceCard, page.TextAppearanceHint, page.TextOutlineLabel, page.TextOutlineButton, page.TextOverlaySizeStepper)
	if page.SubcategoryFullLabels then
		page.SubcategoryFullLabels:ClearAllPoints()
		local lastRow = page.TextStyleRows and page.TextStyleRows[#page.TextStyleRows] or nil
		if lastRow then
			page.SubcategoryFullLabels:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", -4, -10)
		else
			page.SubcategoryFullLabels:SetPoint("TOPLEFT", page.TextOutlineButton, "BOTTOMLEFT", -4, -10)
		end
		if page.SubcategoryFullLabels.Label then
			page.SubcategoryFullLabels.Label:ClearAllPoints()
			page.SubcategoryFullLabels.Label:SetPoint("LEFT", page.SubcategoryFullLabels, "RIGHT", 4, 1)
			page.SubcategoryFullLabels.Label:SetPoint("RIGHT", page.TextAppearanceCard, "RIGHT", -14, 0)
			page.SubcategoryFullLabels.Label:SetJustifyH("LEFT")
			page.SubcategoryFullLabels.Label:SetWordWrap(false)
		end
	end
	if page.TextPreviewLabel then
		page.TextPreviewLabel:ClearAllPoints()
		page.TextPreviewLabel:SetPoint("LEFT", page.TextAppearanceCard, "LEFT", 14, 0)
		if showAdvancedLookControls and page.SubcategoryFullLabels then
			page.TextPreviewLabel:SetPoint("TOP", page.SubcategoryFullLabels, "BOTTOM", 0, -18)
		else
			page.TextPreviewLabel:SetPoint("TOP", page.TextOutlineButton, "BOTTOM", 0, -18)
		end
	end
end

applyFooterPageMode = function(page)
	if not page then
		return
	end

	local basicMode = isBasicCategoryMode()
	if page.TrackedCharactersCard then
		page.TrackedCharactersCard:SetShown(not basicMode)
	end
end

local function createCategoryModeCard(parent)
	local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	createCardBackdrop(card)

	local title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -12)
	title:SetText(L["settingsCategoryModeTitle"] or "Category mode")
	card.Title = title

	local status = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	status:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	status:SetJustifyH("LEFT")
	card.Status = status

	local description = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -4)
	description:SetPoint("RIGHT", card, "RIGHT", -220, 0)
	description:SetJustifyH("LEFT")
	description:SetJustifyV("TOP")
	card.Description = description

	local switchButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
	switchButton:SetSize(174, 24)
	switchButton:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -16)
	switchButton:SetScript("OnClick", function()
		local targetMode = isBasicCategoryMode() and "advanced" or "basic"
		if addon.SetActiveCategoryMode then
			addon.SetActiveCategoryMode(targetMode)
		end
		requestBagRefresh(true, true)
		addon.RefreshSettingsFrame("layout", true)
	end)
	card.SwitchButton = switchButton

	local copyButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
	copyButton:SetSize(174, 24)
	copyButton:SetPoint("TOPRIGHT", switchButton, "BOTTOMRIGHT", 0, -8)
	card.CopyButton = copyButton

	return card
end

local function refreshSettingsNavigation(frame)
	if not frame then
		return
	end

	local visibleButtons = {}
	local previousButton
	for _, button in ipairs(frame.PageButtons or {}) do
		local visible = isSettingsPageVisibleForMode(button.pageID)
		button:SetShown(visible)
		if visible then
			button:ClearAllPoints()
			if previousButton then
				button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -6)
			else
				button:SetPoint("TOPLEFT", frame.NavPanel, "TOPLEFT", 0, 0)
			end
			visibleButtons[#visibleButtons + 1] = button
			previousButton = button
		end
	end

	local visibleCount = #visibleButtons
	frame.NavPanel:SetHeight(math.max(55, (visibleCount * 55) + (math.max(0, visibleCount - 1) * 6)))
	settingsState.selectedPage = normalizeSettingsPageID(settingsState.selectedPage)
end

updateCategoryModeCard = function(frame)
	if not frame or not frame.ModeCard then
		return
	end

	local activeMode = getActiveCategoryMode()
	local basicMode = activeMode == "basic"
	frame.ModeCard.Status:SetText(basicMode and (L["settingsCategoryModeBasic"] or "Basic") or (L["settingsCategoryModeAdvanced"] or "Advanced"))
	frame.ModeCard.Description:SetText(
		basicMode
			and (L["settingsCategoryModeBasicDescription"] or "Uses a curated preset and hides the category editor.")
			or (L["settingsCategoryModeAdvancedDescription"] or "Starts plain and keeps all rule and group editing available.")
	)
	frame.ModeCard.SwitchButton:SetText(
		basicMode
			and (L["settingsCategoryModeSwitchAdvanced"] or "Switch to Advanced")
			or (L["settingsCategoryModeSwitchBasic"] or "Switch to Basic")
	)
	frame.ModeCard.CopyButton:SetShown(not basicMode)
	if not basicMode then
		frame.ModeCard.CopyButton:SetText(L["settingsCategoryModeCopyBasic"] or "Copy Basic to Advanced")
		frame.ModeCard.CopyButton:SetScript("OnClick", function()
			StaticPopup_Show("BAGS_COPY_BASIC_TO_ADVANCED_CONFIRM")
		end)
	end
end

refreshSettingsUI = function(frame)
	if not frame then
		return
	end

	refreshSettingsNavigation(frame)
	updateCategoryModeCard(frame)
	if frame.Pages and frame.Pages.layout then
		applyLayoutPageMode(frame.Pages.layout)
	end
	if frame.Pages and frame.Pages.footer then
		applyFooterPageMode(frame.Pages.footer)
	end
end

if type(StaticPopupDialogs) == "table" then
	StaticPopupDialogs["BAGS_COPY_BASIC_TO_ADVANCED_CONFIRM"] = {
		text = L["settingsCategoryModeCopyConfirm"] or "This will overwrite all current Advanced categories, groups, hidden defaults, and rules with a fresh copy of Basic. Continue?",
		button1 = YES or "Yes",
		button2 = NO or "No",
		OnAccept = function()
			if addon.CopyBasicCategoriesToAdvanced then
				addon.CopyBasicCategoriesToAdvanced()
			end
			requestBagRefresh(true, true)
			addon.RefreshSettingsFrame("categories", true)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = STATICPOPUP_NUMDIALOGS,
	}
end

local function createModeChoiceButton(parent, width, titleText, bodyText, actionLabel, onClick)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width, 208)
	createCardBackdrop(button)
	button:RegisterForClicks("LeftButtonUp")
	button:SetScript("OnClick", onClick)

	local title = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", button, "TOPLEFT", 14, -14)
	title:SetPoint("RIGHT", button, "RIGHT", -14, 0)
	title:SetJustifyH("LEFT")
	title:SetText(titleText)
	button.Title = title

	local body = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	body:SetPoint("RIGHT", button, "RIGHT", -14, 0)
	body:SetJustifyH("LEFT")
	body:SetJustifyV("TOP")
	body:SetText(bodyText)
	button.Body = body

	local action = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
	action:SetSize(150, 24)
	action:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 14, 14)
	action:SetText(actionLabel)
	action:SetScript("OnClick", function()
		onClick()
	end)
	button.ActionButton = action

	return button
end

createCategoryModeOnboardingFrame = function()
	if settingsState.onboardingFrame then
		return settingsState.onboardingFrame
	end

	local frame = CreateFrame("Frame", "BagsCategoryModeOnboardingFrame", UIParent)
	frame:SetSize(600, 320)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:Hide()
	tinsert(UISpecialFrames, "BagsCategoryModeOnboardingFrame")

	createQuestLogPanel(frame)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", frame, "TOP", 0, -16)
	title:SetText(L["settingsCategoryModeOnboardingTitle"] or "Choose your category mode")
	frame.TitleText = title

	local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	body:SetPoint("TOPLEFT", frame.PanelBackground, "TOPLEFT", 20, -32)
	body:SetPoint("RIGHT", frame.PanelBackground, "RIGHT", -20, 0)
	body:SetJustifyH("LEFT")
	body:SetJustifyV("TOP")
	body:SetText(L["settingsCategoryModeOnboardingDescription"] or "Basic starts with curated parent groups. Advanced starts empty and keeps the full editor available.")
	frame.BodyText = body

	local function finishOnboarding(mode)
		if addon.SetActiveCategoryMode then
			addon.SetActiveCategoryMode(mode)
		end
		if addon.SetCategoryModeOnboardingComplete then
			addon.SetCategoryModeOnboardingComplete(true)
		end
		frame:Hide()
		requestBagRefresh(true, true)
	end

	local cardWidth = 262
	local gap = 16
	local basicButton = createModeChoiceButton(
		frame,
		cardWidth,
		L["settingsCategoryModeBasic"] or "Basic",
		L["settingsCategoryModeOnboardingBasicDescription"] or "Uses curated parent groups and only exposes a small, safe settings surface.",
		L["settingsCategoryModeOnboardingChooseBasic"] or "Use Basic",
		function()
			finishOnboarding("basic")
		end
	)
	basicButton:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -18)
	frame.BasicButton = basicButton

	local advancedButton = createModeChoiceButton(
		frame,
		cardWidth,
		L["settingsCategoryModeAdvanced"] or "Advanced",
		L["settingsCategoryModeOnboardingAdvancedDescription"] or "Starts plain and keeps the full rule, group and category editor available.",
		L["settingsCategoryModeOnboardingChooseAdvanced"] or "Use Advanced",
		function()
			finishOnboarding("advanced")
		end
	)
	advancedButton:SetPoint("TOPLEFT", basicButton, "TOPRIGHT", gap, 0)
	frame.AdvancedButton = advancedButton

	settingsState.onboardingFrame = frame
	return frame
end

function addon.OpenCategoryModeOnboarding()
	if addon.IsCategoryModeOnboardingComplete and addon.IsCategoryModeOnboardingComplete() then
		return
	end

	local frame = createCategoryModeOnboardingFrame()
	frame:Show()
	frame:Raise()
end

local function createSettingsFrame()
	if settingsState.frame then
		return settingsState.frame
	end

	local settingsFrameDB = getSettingsFrameDB()
	local initialWidth, initialHeight = getClampedSettingsFrameSize(settingsFrameDB.width, settingsFrameDB.height)

	local frame = CreateFrame("Frame", "BagsSettingsFrame", UIParent)
	frame:SetSize(initialWidth, initialHeight)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetClampedToScreen(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(MIN_SETTINGS_WIDTH, MIN_SETTINGS_HEIGHT, nil, nil)
	elseif frame.SetMinResize then
		frame:SetMinResize(MIN_SETTINGS_WIDTH, MIN_SETTINGS_HEIGHT)
	end
	frame:Hide()
	tinsert(UISpecialFrames, "BagsSettingsFrame")

	local background = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	background:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
	if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("Relicforge-Relicsbackground-Previewtraits") then
		background:SetAtlas("Relicforge-Relicsbackground-Previewtraits")
	else
		background:SetColorTexture(0.2, 0.25, 0.33, 1)
	end
	background:SetAlpha(0.95)
	frame.Background = background

	local backgroundShade = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	backgroundShade:SetAllPoints(background)
	backgroundShade:SetColorTexture(0.02, 0.03, 0.06, 0.32)
	frame.BackgroundShade = backgroundShade

	createQuestLogPanel(frame)
	frame.ContentPanel = frame

	local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleText:SetPoint("TOP", frame, "TOP", 0, -11)
	titleText:SetJustifyH("CENTER")
	titleText:SetText(string.format("%s %s", addon.metadata.title or addonName, L["settingsTitleSuffix"] or "Settings"))
	titleText:SetTextColor(1, 0.82, 0)
	frame.TitleText = titleText

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButtonNoScripts")
	closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
	closeButton:SetScript("OnClick", function()
		frame:Hide()
	end)
	frame.CloseButton = closeButton

	local resizeButton = CreateFrame("Button", nil, frame)
	resizeButton:SetSize(16, 16)
	resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
	resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	resizeButton:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then
			return
		end

		self:SetButtonState("PUSHED", true)
		if self:GetHighlightTexture() then
			self:GetHighlightTexture():Hide()
		end
		frame.isResizing = true
		frame:StartSizing("BOTTOMRIGHT")
	end)
	resizeButton:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then
			return
		end

		self:SetButtonState("NORMAL")
		if self:GetHighlightTexture() then
			self:GetHighlightTexture():Show()
		end
		frame:StopMovingOrSizing()

		local width, height = getClampedSettingsFrameSize(frame:GetSize())
		frame:SetSize(width, height)
		frame.isResizing = false
		saveSettingsFrameSize(frame)
		if frame:IsShown() then
			addon.RefreshSettingsFrame(settingsState.selectedPage)
		end
	end)
	frame.ResizeButton = resizeButton

	local dragBar = CreateFrame("Frame", nil, frame)
	dragBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -4)
	dragBar:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -8, 0)
	dragBar:SetHeight(20)
	dragBar:EnableMouse(true)
	dragBar:RegisterForDrag("LeftButton")
	dragBar:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	dragBar:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)
	frame.DragBar = dragBar

	local navPanel = CreateFrame("Frame", nil, frame)
	navPanel:SetPoint("TOPLEFT", frame, "TOPRIGHT", -3, -42)
	navPanel:SetWidth(43)
	navPanel:SetHeight((#PAGE_ORDER * 55) + ((#PAGE_ORDER - 1) * 6))
	frame.NavPanel = navPanel

	frame.Pages = {}
	frame.PageButtons = {}

	local buttonAnchor = nil
	for index, pageInfo in ipairs(PAGE_ORDER) do
		local button = createSideTabButton(navPanel, pageInfo)
		if index == 1 then
			button:SetPoint("TOPLEFT", navPanel, "TOPLEFT", 0, 0)
		else
			button:SetPoint("TOPLEFT", buttonAnchor, "BOTTOMLEFT", 0, -6)
		end
		frame.PageButtons[#frame.PageButtons + 1] = button
		buttonAnchor = button
	end

	local modeCard = createCategoryModeCard(frame)
	modeCard:SetPoint("TOPLEFT", frame.PanelBackground, "TOPLEFT", 24, -30)
	modeCard:SetPoint("TOPRIGHT", frame.PanelBackground, "TOPRIGHT", -28, -30)
	modeCard:SetHeight(84)
	frame.ModeCard = modeCard

	local pageContainer = CreateFrame("Frame", nil, frame)
	pageContainer:SetPoint("TOPLEFT", modeCard, "BOTTOMLEFT", 0, -12)
	pageContainer:SetPoint("BOTTOMRIGHT", frame.PanelBackground, "BOTTOMRIGHT", -28, 24)
	frame.PageContainer = pageContainer

	frame.Pages.layout = createLayoutPage(pageContainer)
	frame.Pages.categories = createCategoriesPage(pageContainer)
	frame.Pages.overlays = createOverlaysPage(pageContainer)
	frame.Pages.footer = createFooterPage(pageContainer)
	frame.Pages.tracking = createTrackingPage(pageContainer)

	frame:SetScript("OnShow", function()
		refreshSettingsUI(frame)
		local selectedPage = normalizeSettingsPageID(settingsState.selectedPage or PAGE_ORDER[1].id)
		setPageSelection(selectedPage)
		addon.RefreshSettingsFrame(selectedPage)
	end)
	frame:SetScript("OnSizeChanged", function(self)
		saveSettingsFrameSize(self)
		if self:IsShown() and not self.isResizing then
			addon.RefreshSettingsFrame(settingsState.selectedPage)
		end
	end)

	settingsState.frame = frame
	return frame
end

function addon.RefreshSettingsFrame(pageID, refreshAll)
	local frame = settingsState.frame
	if not frame then
		return
	end

	local settings = getSettings()
	refreshSettingsUI(frame)
	local selectedPage = normalizeSettingsPageID(pageID or settingsState.selectedPage or PAGE_ORDER[1].id)

	local function refreshSinglePage(targetPageID)
		if targetPageID == "layout" then
			if frame.Pages.layout then
				refreshLayoutPage(frame.Pages.layout)
			end
		elseif targetPageID == "categories" then
			if frame.Pages.categories then
				refreshCategoriesPage(frame.Pages.categories)
			end
		elseif targetPageID == "footer" then
			if frame.Pages.footer then
				refreshFooterPage(frame.Pages.footer, settings)
			end
		elseif targetPageID == "overlays" then
			if frame.Pages.overlays then
				refreshOverlaysPage(frame.Pages.overlays)
			end
		elseif targetPageID == "tracking" then
			if frame.Pages.tracking then
				refreshTrackingPage(frame.Pages.tracking, settings)
			end
		end
	end

	if refreshAll then
		for _, pageInfo in ipairs(PAGE_ORDER) do
			refreshSinglePage(pageInfo.id)
		end
	else
		refreshSinglePage(selectedPage)
	end
end

function addon.OpenSettings(pageID)
	local frame = createSettingsFrame()
	local wasShown = frame:IsShown()
	frame:Show()
	frame:Raise()
	if wasShown then
		refreshSettingsUI(frame)
		local selectedPage = normalizeSettingsPageID(pageID or settingsState.selectedPage or PAGE_ORDER[1].id)
		setPageSelection(selectedPage)
		addon.RefreshSettingsFrame(selectedPage)
	end
end

function addon.ToggleSettings(pageID)
	local frame = createSettingsFrame()
	if frame:IsShown() then
		frame:Hide()
	else
		addon.OpenSettings(pageID)
	end
end
