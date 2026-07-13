-- luacheck: globals ACCOUNT_BANK_TITLE ACCOUNT_BANK_DEPOSIT_BUTTON_LABEL CHARACTER_BANK_DEPOSIT_BUTTON_LABEL C_Bank C_Cursor C_Timer ItemUtil ScrollFrameTemplate_OnMouseWheel BANK_DEPOSIT_INCLUDE_REAGENTS_CHECKBOX_LABEL ClearItemButtonOverlay SetItemButtonQuality SetItemButtonTextureVertexColor ItemButtonUtil PanelTemplates_TabResize ITEM_SEARCHBAR_LIST BagSearch_OnHide BagSearch_OnTextChanged BagSearch_OnChar BankPanelIncludeReagentsCheckboxMixin BankPanelPurchaseTabButtonMixin UIPanelScrollFrame_OnLoad COPPER_PER_GOLD COPPER_PER_SILVER WHITE_FONT_COLOR COSTS PVP_ITEM_LEVEL_TOOLTIP
local addon = _G.EnhanceQoL
if not addon then error("EnhanceQoL is not loaded") end

addon.Bags = addon.Bags or {}
addon.Bags.functions = addon.Bags.functions or {}
addon.Bags.variables = addon.Bags.variables or {}

local Bags = addon.Bags
local L = addon.L or {}

local CHARACTER_BANK_TYPE = Enum and Enum.BankType and Enum.BankType.Character or 0
local ACCOUNT_BANK_TYPE = Enum and Enum.BankType and Enum.BankType.Account or 2
local ITEM_QUALITY_POOR = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0

local BUTTON_SIZE = 37
local BUTTON_SPACING = 4
local DEFAULT_COLUMN_COUNT = 18
local FRAME_PADDING = 10
local HEADER_HEIGHT = 124
local ACTION_BAR_TOP_OFFSET = 64
local ACTION_ROW_HEIGHT = 24
local ACTION_ROW_GAP = 4
local ACTION_BAR_HEIGHT = (ACTION_ROW_HEIGHT * 2) + ACTION_ROW_GAP
local SECTION_HEADER_HEIGHT = 18
local GROUP_HEADER_HEIGHT = SECTION_HEADER_HEIGHT
local GROUP_HEADER_GAP = 4
local SECTION_CONTENT_TOP_PADDING = 6
local SECTION_GAP = 10
local SECTION_HORIZONTAL_GAP = 8
local GROUP_SPACER_TOP_GAP = 6
local GROUP_SPACER_BOTTOM_GAP = 8
local CLUSTER_GAP = 12
local MIN_FRAME_WIDTH = 420
local MIN_SCROLL_CONTENT_HEIGHT = 160
local MAX_FRAME_SCREEN_MARGIN = 120
local SCROLL_BAR_RESERVED_WIDTH = 22
local SECTION_TOGGLE_LEFT_ATLAS = "Options_ListExpand_Left"
local SECTION_TOGGLE_COLLAPSED_ATLAS = "Options_ListExpand_Right"
local SECTION_TOGGLE_EXPANDED_ATLAS = "Options_ListExpand_Right_Expanded"
local SECTION_TOGGLE_LEFT_WIDTH = 4
local SECTION_TOGGLE_RIGHT_WIDTH = SECTION_HEADER_HEIGHT
local SECTION_TOGGLE_WIDTH = SECTION_TOGGLE_LEFT_WIDTH + SECTION_TOGGLE_RIGHT_WIDTH
local MIN_ITEM_LEVEL_COLOR_QUALITY = Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon or 2
local DEPOSIT_BUTTON_WIDTH = 220
local MONEY_BUTTON_WIDTH = 96
local GET_BAG_ITEM_TOOLTIP = C_TooltipInfo and C_TooltipInfo.GetBagItem
local EQUIPMENT_SET_OVERLAY_FALLBACK_TEXTURE = "Interface\\PaperDollInfoFrame\\UI-EquipmentManager-Toggle"
local CONSUMABLE_CLASS_ID = 0
local CONSUMABLE_OTHER_SUBCLASS_ID = 8
local LEARN_TRANSMOG_SET_TOOLTIP_LINE_TYPE = 39
local TOY_TOOLTIP_LINE_TYPE = 0
local KNOWN_SPELL_TOOLTIP_LINE_TYPE = 43

local FREE_SLOTS_SECTION_ID = "warbandFreeSlots"
local FREE_SLOTS_DEFINITION = {
	id = FREE_SLOTS_SECTION_ID,
	labelKey = "categoryFreeSlots",
	color = { 0.9, 0.78, 0.28 },
}
local NEW_ITEMS_SECTION_ID = "warbandNewItems"
local NEW_ITEMS_DEFINITION = {
	id = NEW_ITEMS_SECTION_ID,
	labelKey = "categoryNewItems",
	color = { 0.48, 0.82, 0.34 },
	collapsible = false,
	forceHeader = true,
}

local HEARTHSTONE_ITEM_IDS = {
	[6948] = true,
	[110560] = true,
	[140192] = true,
}

local applyConfiguredFont
local getConfiguredBaseTextSize
local getCachedRuleItemInfo
local isOpenSessionNewItem

local IGNORED_ITEM_LEVEL_EQUIP_LOCS = {
	[""] = true,
	INVTYPE_BAG = true,
	INVTYPE_BODY = true,
	INVTYPE_NON_EQUIP_IGNORE = true,
	INVTYPE_QUIVER = true,
	INVTYPE_TABARD = true,
}

local EQUIP_LOCATION_COMPARISON_SLOTS = {
	INVTYPE_HEAD = { INVSLOT_HEAD or 1 },
	INVTYPE_NECK = { INVSLOT_NECK or 2 },
	INVTYPE_SHOULDER = { INVSLOT_SHOULDER or 3 },
	INVTYPE_CHEST = { INVSLOT_CHEST or 5 },
	INVTYPE_ROBE = { INVSLOT_CHEST or 5 },
	INVTYPE_WAIST = { INVSLOT_WAIST or 6 },
	INVTYPE_LEGS = { INVSLOT_LEGS or 7 },
	INVTYPE_FEET = { INVSLOT_FEET or 8 },
	INVTYPE_WRIST = { INVSLOT_WRIST or 9 },
	INVTYPE_HAND = { INVSLOT_HAND or 10 },
	INVTYPE_FINGER = { INVSLOT_FINGER1 or 11, INVSLOT_FINGER2 or 12 },
	INVTYPE_TRINKET = { INVSLOT_TRINKET1 or 13, INVSLOT_TRINKET2 or 14 },
	INVTYPE_CLOAK = { INVSLOT_BACK or 15 },
	INVTYPE_WEAPON = { INVSLOT_MAINHAND or 16, INVSLOT_OFFHAND or 17 },
	INVTYPE_SHIELD = { INVSLOT_OFFHAND or 17 },
	INVTYPE_2HWEAPON = { INVSLOT_MAINHAND or 16 },
	INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND or 16 },
	INVTYPE_WEAPONOFFHAND = { INVSLOT_OFFHAND or 17 },
	INVTYPE_HOLDABLE = { INVSLOT_OFFHAND or 17 },
	INVTYPE_RANGED = { INVSLOT_MAINHAND or 16 },
	INVTYPE_RANGEDRIGHT = { INVSLOT_MAINHAND or 16 },
}

local ACTIVE_EVENTS = {
	"BAG_UPDATE",
	"BAG_UPDATE_DELAYED",
	"BAG_NEW_ITEMS_UPDATED",
	"ITEM_LOCK_CHANGED",
	"BAG_UPDATE_COOLDOWN",
	"PLAYER_MONEY",
	"ACCOUNT_MONEY",
	"PLAYERBANKSLOTS_CHANGED",
	"PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED",
	"BANK_TABS_CHANGED",
	"BANK_TAB_SETTINGS_UPDATED",
	"INVENTORY_SEARCH_UPDATE",
	"TOYS_UPDATED",
	"NEW_TOY_ADDED",
	"ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
	"PLAYER_LEVEL_UP",
}

local ACTIVE_UNIT_EVENTS = {
	{
		name = "UNIT_INVENTORY_CHANGED",
		unit = "player",
	},
}

local DEFAULT_FRAME_POINT = {
	point = "RIGHT",
	relativePoint = "RIGHT",
	x = -860,
	y = 0,
}

local BANK_CONTEXT_TABS = {
	{
		id = "characterBank",
		label = BANK or "Bank",
	},
	{
		id = "accountBank",
		label = ACCOUNT_BANK_PANEL_TITLE or ACCOUNT_BANK_TITLE or "Warband Bank",
	},
}

local state = Bags.variables.warbandBankState or {}
Bags.variables.warbandBankState = state
state.buttons = state.buttons or {}
state.slotMappings = state.slotMappings or {}
state.sectionHeaders = state.sectionHeaders or {}
state.groupSpacers = state.groupSpacers or {}
state.itemRuleDataCache = state.itemRuleDataCache or {}
state.tooltipBindTypeCache = state.tooltipBindTypeCache or {}
state.tooltipDerivedItemFlagsCache = state.tooltipDerivedItemFlagsCache or {}
state.overlayBindStatusCache = state.overlayBindStatusCache or {}
state.slotCategoryCache = state.slotCategoryCache or {}
state.openSessionNewItems = state.openSessionNewItems or {}
state.dirtyBags = state.dirtyBags or {}
state.dirtyBagCount = state.dirtyBagCount or 0
state.pendingRebuildReasons = state.pendingRebuildReasons or {}
state.pendingRefreshReasons = state.pendingRefreshReasons or {}
state.activeContextID = state.activeContextID or nil
state.forceDynamicRefresh = false
if state.playerRuleRevision == nil then
	state.playerRuleRevision = 0
end

local itemLevelEligibilityCache = {}
state.pvpItemTooltipPattern = PVP_ITEM_LEVEL_TOOLTIP
	and addon.functions
	and addon.functions.fmtToPattern
	and addon.functions.fmtToPattern(PVP_ITEM_LEVEL_TOOLTIP)
	or nil
local cachedOverlayRuntimeConfig
local scheduleUpdate
local applyActiveSkin
local getVisibleContext
local installFrameDropReceiver
local hiddenBankFrameParent = CreateFrame("Frame")
hiddenBankFrameParent:Hide()

local function getSettings()
	if addon.GetSettings then
		return addon.GetSettings()
	end

	addon.DB = addon.DB or {}
	addon.DB.settings = addon.DB.settings or {}
	return addon.DB.settings
end

local function wipeTable(tbl)
	if not tbl then
		return
	end
	if wipe then
		wipe(tbl)
		return
	end
	for key in pairs(tbl) do
		tbl[key] = nil
	end
end

state.getPerfBucket = state.getPerfBucket or function()
	addon.BagsPerf = addon.BagsPerf or {}
	addon.BagsPerf.bank = addon.BagsPerf.bank or {
		schedule = {},
		rebuildRequests = {},
		refreshRequests = {},
		rebuilds = {},
		refreshes = {},
		skips = {},
		crossBackpackRefreshRequests = 0,
		dirtyBagsMarked = 0,
		dirtyBagsIgnored = 0,
		dirtyBagDelayedEvents = 0,
		newItemEvents = 0,
		newItemEventsSkippedNoBankNewItems = 0,
	}
	return addon.BagsPerf.bank
end

state.countReason = state.countReason or function(bucket, reason)
	if type(bucket) ~= "table" then return end
	reason = reason or "unknown"
	bucket[reason] = (bucket[reason] or 0) + 1
end

state.addPendingReason = state.addPendingReason or function(target, reason)
	if type(target) ~= "table" or not reason then return end
	target[reason] = true
end

state.consumeReasons = state.consumeReasons or function(target)
	if type(target) ~= "table" then return "unknown" end
	local text
	for reason in pairs(target) do
		text = text and (text .. "," .. reason) or reason
		target[reason] = nil
	end
	return text or "unknown"
end

local function clearTooltipDerivedItemFlagsCache()
	wipeTable(state.tooltipDerivedItemFlagsCache)
end

local function refreshHeaderControls()
	if not state.frame then
		return
	end

	local frame = state.frame
	local showCloseButton = addon.GetShowCloseButton == nil or addon.GetShowCloseButton()
	if frame.CloseButton then
		frame.CloseButton:ClearAllPoints()
		frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PADDING + 4, -4)
		frame.CloseButton:SetShown(showCloseButton)
	end
	if frame.SettingsButton then
		frame.SettingsButton:ClearAllPoints()
		if showCloseButton and frame.CloseButton then
			frame.SettingsButton:SetPoint("RIGHT", frame.CloseButton, "LEFT", -4, 0)
		else
			frame.SettingsButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PADDING, -8)
		end
	end
	if frame.SearchBox and frame.Title and frame.SettingsButton then
		frame.SearchBox:ClearAllPoints()
		frame.SearchBox:SetPoint("TOPLEFT", frame.Title, "TOPRIGHT", 18, 2)
		frame.SearchBox:SetPoint("TOPRIGHT", frame.SettingsButton, "TOPLEFT", -10, -1)
	end
end

local function getFrameDB()
	addon.DB = addon.DB or {}
	addon.DB.bankFrame = addon.DB.bankFrame or addon.DB.warbandBankFrame or {}
	addon.DB.warbandBankFrame = addon.DB.bankFrame
	return addon.DB.bankFrame
end

local function getCollapsedSectionsTable()
	local settings = getSettings()
	settings.collapsedBankSections = settings.collapsedBankSections or settings.collapsedWarbandSections or {}
	settings.collapsedWarbandSections = settings.collapsedBankSections
	return settings.collapsedBankSections
end

local function unpackSkinColor(color, defaultR, defaultG, defaultB, defaultA)
	return color and color[1] or defaultR or 1,
		color and color[2] or defaultG or 1,
		color and color[3] or defaultB or 1,
		color and color[4] or defaultA or 1
end

local function getActiveFrameSkin()
	local definition = addon.GetActiveSkinDefinition and addon.GetActiveSkinDefinition() or nil
	return definition and definition.frame or nil
end

local function applySectionHeaderSkin(header, skin)
	if not header or not skin then
		return
	end

	if header.HighlightTexture then
		header.HighlightTexture:SetColorTexture(unpackSkinColor(skin.sectionHighlightColor, 1, 1, 1, 0.08))
	end
end

local function applyTabButtonSkin(tab, isSelected, skin)
	if not tab or not skin then
		return
	end

	local text = tab.Text or (tab.GetFontString and tab:GetFontString()) or nil
	if text then
		if isSelected then
			text:SetTextColor(unpackSkinColor(skin.titleColor, 1, 0.82, 0.00, 1))
		else
			text:SetTextColor(unpackSkinColor(skin.accentColor, 1, 0.82, 0.00, 1))
		end
	end
end

applyActiveSkin = function()
	local skin = getActiveFrameSkin()
	if not skin then
		state.currentSkinSignature = addon.GetSkinSignature and addon.GetSkinSignature() or nil
		return
	end

	if state.frame then
		local frame = state.frame
		refreshHeaderControls()
		if addon.ApplyFrameBackgroundSkin then
			addon.ApplyFrameBackgroundSkin(frame, skin)
		else
			frame:SetBackdropColor(unpackSkinColor(skin.backdropColor, 0.05, 0.06, 0.08, 0.94))
		end
		if not frame.CustomBorderFrame then
			frame:SetBackdropBorderColor(unpackSkinColor(skin.borderColor, 0.35, 0.35, 0.42, 1))
		else
			frame:SetBackdropBorderColor(0, 0, 0, 0)
		end
		if frame.Divider then
			frame.Divider:SetColorTexture(unpackSkinColor(skin.dividerColor, 1, 1, 1, 0.08))
		end
		if frame.Title then
			frame.Title:SetTextColor(unpackSkinColor(skin.titleColor, 1, 0.82, 0.00, 1))
		end
		if frame.SettingsButton and frame.SettingsButton.HighlightTexture then
			frame.SettingsButton.HighlightTexture:SetVertexColor(unpackSkinColor(skin.accentColor, 1, 1, 1, 1))
			frame.SettingsButton.HighlightTexture:SetAlpha(0.4)
		end
		if frame.SearchBox and frame.SearchBox.Instructions then
			frame.SearchBox.Instructions:SetTextColor(unpackSkinColor(skin.accentColor, 0.78, 0.78, 0.78, 1))
		end
		if frame.ActionBar and frame.ActionBar.WarbandGoldText then
			frame.ActionBar.WarbandGoldText:SetTextColor(unpackSkinColor(skin.titleColor, 1, 1, 1, 1))
		end
	end

	for _, header in ipairs(state.sectionHeaders or {}) do
		applySectionHeaderSkin(header, skin)
	end

	for _, spacer in ipairs(state.groupSpacers or {}) do
		if spacer and spacer.Line then
			spacer.Line:SetColorTexture(unpackSkinColor(skin and skin.dividerColor, 1, 1, 1, 0.08))
		end
	end

	for index, tab in ipairs(state.frame and state.frame.Tabs or {}) do
		applyTabButtonSkin(tab, index == (state.frame and state.frame.selectedTab or 0), skin)
	end

	state.currentSkinSignature = addon.GetSkinSignature and addon.GetSkinSignature() or nil
end

local function formatMoneyString(amount)
	amount = math.max(0, tonumber(amount) or 0)
	if addon.GetMoneyFormat and addon.GetMoneyFormat() == "letters" then
		local gold = math.floor(amount / COPPER_PER_GOLD)
		local silver = math.floor((amount % COPPER_PER_GOLD) / COPPER_PER_SILVER)
		local copper = amount % COPPER_PER_SILVER
		return string.format("%dg %ds %db", gold, silver, copper)
	end
	if type(GetMoneyString) == "function" then
		return GetMoneyString(amount, true)
	elseif C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
		return C_CurrencyInfo.GetCoinTextureString(amount, 12)
	end

	return tostring(amount)
end

local function getNextPurchasableBankTabData(bankType)
	if not bankType or not C_Bank or not C_Bank.FetchNextPurchasableBankTabData then
		return nil
	end

	return C_Bank.FetchNextPurchasableBankTabData(bankType)
end

local function canPurchaseBankTab(bankType)
	if not bankType or not C_Bank or not C_Bank.CanPurchaseBankTab or not C_Bank.HasMaxBankTabs then
		return false
	end

	return C_Bank.CanPurchaseBankTab(bankType) and not C_Bank.HasMaxBankTabs(bankType)
end

local function getBankTypeForContextID(contextID)
	if contextID == "accountBank" then
		return ACCOUNT_BANK_TYPE
	elseif contextID == "characterBank" then
		return CHARACTER_BANK_TYPE
	end

	return nil
end

local function getBankTypeForContext(context)
	return getBankTypeForContextID(context and context.id or nil)
end

local function showBankTabPurchaseTooltip(owner, bankType)
	if not owner or not GameTooltip then
		return
	end

	GameTooltip:SetOwner(owner, "ANCHOR_TOP")
	local tabData = getNextPurchasableBankTabData(bankType)
	if tabData and tabData.purchasePromptTitle then
		GameTooltip:SetText(tabData.purchasePromptTitle, 1, 0.82, 0)
	elseif bankType == ACCOUNT_BANK_TYPE then
		GameTooltip:SetText(ACCOUNT_BANK_PANEL_TITLE or ACCOUNT_BANK_TITLE or "Warband Bank", 1, 0.82, 0)
	else
		GameTooltip:SetText(BANKSLOTPURCHASE or "Purchase", 1, 0.82, 0)
	end

	if tabData and tabData.tabCost then
		local color = tabData.canAfford and WHITE_FONT_COLOR or RED_FONT_COLOR
		local costText = formatMoneyString(tabData.tabCost)
		if color and color.WrapTextInColorCode then
			costText = color:WrapTextInColorCode(costText)
		end
		GameTooltip:AddLine((COSTS_LABEL or COSTS or "Cost") .. ": " .. costText, 1, 1, 1, true)
	end

	if tabData and tabData.purchasePromptBody then
		GameTooltip:AddLine(tabData.purchasePromptBody, 0.78, 0.78, 0.78, true)
	end
	GameTooltip:Show()
end

local function openBankTabPurchaseDialog(bankType)
	if not bankType or not StaticPopup_Show then
		return
	end

	StaticPopup_Show("CONFIRM_BUY_BANK_TAB", nil, nil, { bankType = bankType })
end

local function createBankTabPurchaseButton(parent)
	local button
	if BankPanelPurchaseTabButtonMixin then
		local ok, createdButton = pcall(CreateFrame, "Button", nil, parent, "BankPanelPurchaseButtonScriptTemplate,UIPanelButtonTemplate")
		if ok then
			button = createdButton
		end
	end

	if not button then
		button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		button:SetScript("OnClick", function(self)
			openBankTabPurchaseDialog(self:GetAttribute("overrideBankType"))
		end)
	end

	button:RegisterForClicks("LeftButtonUp")
	button:SetText(BANKSLOTPURCHASE or "Purchase")
	button:SetScript("OnEnter", function(self)
		showBankTabPurchaseTooltip(self, self:GetAttribute("overrideBankType"))
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return button
end

local function getContextDepositButtonText(context)
	local bankType = getBankTypeForContext(context)
	if bankType == ACCOUNT_BANK_TYPE then
		return ACCOUNT_BANK_DEPOSIT_BUTTON_LABEL or "Deposit All Warbound Items"
	end

	return CHARACTER_BANK_DEPOSIT_BUTTON_LABEL or "Deposit All Reagents"
end

local function getContextLockedReason(context)
	local bankType = getBankTypeForContext(context)
	if bankType and C_Bank and C_Bank.FetchBankLockedReason then
		return C_Bank.FetchBankLockedReason(bankType)
	end

	return nil
end

local function doesContextSupportMoneyTransfer(context)
	local bankType = getBankTypeForContext(context)
	return bankType ~= nil
		and C_Bank
		and C_Bank.DoesBankTypeSupportMoneyTransfer
		and C_Bank.DoesBankTypeSupportMoneyTransfer(bankType)
		or false
end

local function getWarbandMoneyAmount()
	local amount
	if addon.UpdateWarbandGold then
		amount = addon.UpdateWarbandGold()
	end
	if amount == nil and addon.GetWarbandGold then
		amount = addon.GetWarbandGold()
	end
	if amount == nil and C_Bank and C_Bank.FetchDepositedMoney then
		amount = C_Bank.FetchDepositedMoney(ACCOUNT_BANK_TYPE)
	end

	return tonumber(amount) or 0
end

local function sizeButtonToText(button, minWidth, horizontalPadding)
	if not button then
		return
	end

	local fontString = button.GetFontString and button:GetFontString() or button.Text
	local textWidth = fontString and fontString:GetStringWidth() or 0
	button:SetWidth(math.max(minWidth or 0, math.ceil(textWidth + (horizontalPadding or 28))))
end

local function getMeasuredSectionHeaderWidth(label, textElementID)
	if not label or label == "" then
		return BUTTON_SIZE
	end
	if textElementID == "subcategoryHeader" and addon.GetSubcategoryFullLabels and not addon.GetSubcategoryFullLabels() then
		return BUTTON_SIZE
	end

	if not state.sectionHeaderMeasure then
		state.sectionHeaderMeasure = (state.content or UIParent):CreateFontString(nil, "OVERLAY", "GameFontNormal")
		state.sectionHeaderMeasure:Hide()
	end

	local measure = state.sectionHeaderMeasure
	applyConfiguredFont(measure, nil, textElementID or "subcategoryHeader")
	measure:SetText(addon.FormatTextElement and addon.FormatTextElement(textElementID or "subcategoryHeader", label) or label)
	return math.max(BUTTON_SIZE, math.ceil((measure:GetStringWidth() or 0) + SECTION_TOGGLE_WIDTH + 12.5))
end

local function layoutSectionHeaderText(header)
	if not header or not header.Text then
		return
	end

	local leftOffset = 0
	if header.Icon and header.Icon.IsShown and header.Icon:IsShown() then
		leftOffset = math.max(0, math.ceil((header.Icon:GetWidth() or 0) + 4))
	end

	header.Text:ClearAllPoints()
	header.Text:SetPoint("TOPLEFT", header, "TOPLEFT", leftOffset, 0)
	header.Text:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
	header.Text:SetJustifyH("LEFT")
	header.Text:SetJustifyV("MIDDLE")
	header.Text:SetWordWrap(false)
end

local function detachDefaultBankFrames()
	for index = 7, 13 do
		local frame = _G["ContainerFrame" .. index]
		if frame then
			frame:SetParent(hiddenBankFrameParent)
		end
	end

	if BankFrame then
		BankFrame:SetParent(hiddenBankFrameParent)
	end
end

function Bags.functions.RestoreDefaultBankFrames()
	for index = 7, 13 do
		local frame = _G["ContainerFrame" .. index]
		if frame and frame:GetParent() == hiddenBankFrameParent then
			frame:SetParent(UIParent)
		end
	end

	if BankFrame and BankFrame:GetParent() == hiddenBankFrameParent then
		BankFrame:SetParent(UIParent)
	end
end

local function syncBlizzardBankState(context, forceReset)
	detachDefaultBankFrames()

	if not context or not BankFrame or not BankFrame.BankPanel or not BankFrame.BankPanel.SetBankType then
		return
	end

	local bankType = getBankTypeForContext(context)
	if bankType == nil then
		return
	end

	local activeBankType = BankFrame.BankPanel.GetActiveBankType and BankFrame.BankPanel:GetActiveBankType() or nil
	if forceReset or activeBankType ~= bankType then
		BankFrame.BankPanel:SetBankType(bankType)
	end
end

local function syncBlizzardBankStateForContextID(contextID)
	local bankType = getBankTypeForContextID(contextID)
	if bankType == nil then
		return
	end

	syncBlizzardBankState({
		id = contextID,
	}, true)
end

local function getAutoDepositConfirmationPopup(bankType)
	if bankType ~= ACCOUNT_BANK_TYPE
		or not ItemUtil
		or type(ItemUtil.IteratePlayerInventory) ~= "function"
		or not C_Bank
		or not C_Bank.IsItemAllowedInBankType
		or not C_Item
		or not C_Item.CanBeRefunded
	then
		return nil
	end

	local depositContainsRefundableItems = ItemUtil.IteratePlayerInventory(function(itemLocation)
		return C_Bank.IsItemAllowedInBankType(bankType, itemLocation) and C_Item.CanBeRefunded(itemLocation)
	end)

	if depositContainsRefundableItems then
		return "ACCOUNT_BANK_DEPOSIT_ALL_NO_REFUND_CONFIRM"
	end

	return nil
end

local function autoDepositItemsIntoContextBank(context)
	local bankType = getBankTypeForContext(context)
	if bankType == nil or not C_Bank or not C_Bank.AutoDepositItemsIntoBank then
		return
	end

	if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	end

	local popup = getAutoDepositConfirmationPopup(bankType)
	if popup then
		StaticPopup_Show(popup, nil, nil, { bankType = bankType })
	else
		C_Bank.AutoDepositItemsIntoBank(bankType)
	end
end

state.canDepositItemLocationIntoBank = state.canDepositItemLocationIntoBank or function(bankType, itemLocation)
	if bankType == nil or not itemLocation or not C_Bank or not C_Bank.IsItemAllowedInBankType then
		return false
	end

	return C_Bank.IsItemAllowedInBankType(bankType, itemLocation) == true
end

state.getDepositItemLocation = state.getDepositItemLocation or function(bagID, slotID)
	if type(bagID) ~= "number" or type(slotID) ~= "number" then
		return nil
	end
	if not C_Item or not C_Item.DoesItemExist or not ItemLocation then
		return nil
	end

	local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
	if not itemLocation or not itemLocation:IsValid() or not C_Item.DoesItemExist(itemLocation) then
		return nil
	end

	return itemLocation
end

state.CATEGORY_TRANSFER_QUEUE_DELAY = state.CATEGORY_TRANSFER_QUEUE_DELAY or 0.12
state.CATEGORY_TRANSFER_QUEUE_LOCKED_DELAY = state.CATEGORY_TRANSFER_QUEUE_LOCKED_DELAY or 0.2
state.CATEGORY_TRANSFER_QUEUE_MAX_RETRIES = state.CATEGORY_TRANSFER_QUEUE_MAX_RETRIES or 20

state.finishCategoryTransferQueue = state.finishCategoryTransferQueue or function(queue)
	state.categoryTransferQueue = nil
	if queue and queue.movedCount and queue.movedCount > 0 then
		if scheduleUpdate then
			scheduleUpdate(true, true, true, queue.reason or "CategoryTransfer")
		end
		if Bags.functions and Bags.functions.RequestLayoutUpdate then
			Bags.functions.RequestLayoutUpdate(true, true)
		end
	end
end

state.scheduleCategoryTransferQueue = state.scheduleCategoryTransferQueue or function(delay)
	if state.categoryTransferQueueTimerActive then
		return
	end

	if C_Timer and C_Timer.After then
		state.categoryTransferQueueTimerActive = true
		C_Timer.After(delay or state.CATEGORY_TRANSFER_QUEUE_DELAY, function()
			state.categoryTransferQueueTimerActive = false
			if state.processCategoryTransferQueue then
				state.processCategoryTransferQueue()
			end
		end)
	elseif state.processCategoryTransferQueue then
		state.processCategoryTransferQueue()
	end
end

state.getCategoryTransferSlotAction = state.getCategoryTransferSlotAction or function(queue, slotRef)
	local bagID = slotRef and slotRef.bagID
	local slotID = slotRef and slotRef.slotID
	if type(bagID) ~= "number" or type(slotID) ~= "number" or not C_Container or not C_Container.GetContainerItemInfo then
		return nil
	end

	local info = C_Container.GetContainerItemInfo(bagID, slotID)
	if not (info and info.iconFileID) then
		return nil
	end
	if info.isLocked then
		return "locked"
	end

	if queue.kind == "deposit" then
		local itemLocation = state.getDepositItemLocation(bagID, slotID)
		if itemLocation and state.canDepositItemLocationIntoBank(queue.bankType, itemLocation) then
			return "deposit", bagID, slotID
		end
	elseif queue.kind == "withdraw" then
		return "withdraw", bagID, slotID
	end

	return nil
end

state.processCategoryTransferQueue = state.processCategoryTransferQueue or function()
	local queue = state.categoryTransferQueue
	if not queue or type(queue.slots) ~= "table" or not C_Container or not C_Container.UseContainerItem then
		state.finishCategoryTransferQueue(queue)
		return
	end

	local sawLockedSlot = false
	local index = 1
	while index <= #queue.slots do
		local action, bagID, slotID = state.getCategoryTransferSlotAction(queue, queue.slots[index])
		if action == "locked" then
			sawLockedSlot = true
			index = index + 1
		elseif action == "deposit" then
			C_Container.UseContainerItem(bagID, slotID, nil, queue.bankType, false)
			table.remove(queue.slots, index)
			queue.movedCount = (queue.movedCount or 0) + 1
			queue.retryCount = 0
			state.scheduleCategoryTransferQueue(state.CATEGORY_TRANSFER_QUEUE_DELAY)
			return
		elseif action == "withdraw" then
			C_Container.UseContainerItem(bagID, slotID)
			table.remove(queue.slots, index)
			queue.movedCount = (queue.movedCount or 0) + 1
			queue.retryCount = 0
			state.scheduleCategoryTransferQueue(state.CATEGORY_TRANSFER_QUEUE_DELAY)
			return
		else
			table.remove(queue.slots, index)
		end
	end

	if sawLockedSlot and (queue.retryCount or 0) < state.CATEGORY_TRANSFER_QUEUE_MAX_RETRIES then
		queue.retryCount = (queue.retryCount or 0) + 1
		state.scheduleCategoryTransferQueue(state.CATEGORY_TRANSFER_QUEUE_LOCKED_DELAY)
		return
	end

	state.finishCategoryTransferQueue(queue)
end

state.startCategoryTransferQueue = state.startCategoryTransferQueue or function(kind, bankType, slots, reason)
	if kind ~= "deposit" and kind ~= "withdraw" then
		return false
	end
	if type(slots) ~= "table" or #slots == 0 or not C_Container or not C_Container.UseContainerItem then
		return false
	end
	if kind == "deposit" and bankType == nil then
		return false
	end

	state.categoryTransferQueue = {
		kind = kind,
		bankType = bankType,
		slots = slots,
		reason = reason,
		movedCount = 0,
		retryCount = 0,
	}
	state.processCategoryTransferQueue()
	return true
end

state.depositBagSlotsIntoBank = state.depositBagSlotsIntoBank or function(bankType, slots)
	if bankType == nil or type(slots) ~= "table" or not C_Container or not C_Container.UseContainerItem then
		return 0
	end

	return state.startCategoryTransferQueue("deposit", bankType, slots, "CategoryDeposit") and #slots or 0
end

if StaticPopupDialogs and not StaticPopupDialogs.EQOL_BAGS_ACCOUNT_BANK_CATEGORY_DEPOSIT_NO_REFUND_CONFIRM then
	StaticPopupDialogs.EQOL_BAGS_ACCOUNT_BANK_CATEGORY_DEPOSIT_NO_REFUND_CONFIRM = {
		text = END_REFUND,
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = function(_, data)
			if not data or data.bankType ~= ACCOUNT_BANK_TYPE then
				return
			end
			if not C_Bank or not C_Bank.CanUseBank or not C_Bank.CanUseBank(ACCOUNT_BANK_TYPE) then
				return
			end

			state.depositBagSlotsIntoBank(data.bankType, data.slots)
		end,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
	}
end

function addon.DepositBagSlotsIntoCustomBank(slots)
	if type(slots) ~= "table" or #slots == 0 or not (state.frame and state.frame:IsShown() and getVisibleContext()) then
		return false
	end
	if (SpellCanTargetItem and SpellCanTargetItem()) or (SpellCanTargetItemID and SpellCanTargetItemID()) then
		return false
	end

	local context = getVisibleContext()
	local bankType = getBankTypeForContext(context)
	if bankType == nil then
		return false
	end

	if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	end

	local depositableSlots = {}
	local containsRefundableAccountBankItem = false
	for _, slotRef in ipairs(slots) do
		local bagID = slotRef and slotRef.bagID
		local slotID = slotRef and slotRef.slotID
		local itemLocation = state.getDepositItemLocation(bagID, slotID)
		if itemLocation and state.canDepositItemLocationIntoBank(bankType, itemLocation) then
			depositableSlots[#depositableSlots + 1] = {
				bagID = bagID,
				slotID = slotID,
			}
			if bankType == ACCOUNT_BANK_TYPE and C_Item and C_Item.CanBeRefunded and C_Item.CanBeRefunded(itemLocation) then
				containsRefundableAccountBankItem = true
			end
		end
	end

	if #depositableSlots == 0 then
		return false
	end

	if containsRefundableAccountBankItem and StaticPopup_Show then
		StaticPopup_Show("EQOL_BAGS_ACCOUNT_BANK_CATEGORY_DEPOSIT_NO_REFUND_CONFIRM", nil, nil, {
			bankType = bankType,
			slots = depositableSlots,
		})
	else
		state.depositBagSlotsIntoBank(bankType, depositableSlots)
	end

	return true
end

local function getCursorItemLocation()
	if not C_Cursor or not C_Cursor.GetCursorItem or not C_Item or not C_Item.DoesItemExist then
		return nil
	end

	local itemLocation = C_Cursor.GetCursorItem()
	if not itemLocation or not itemLocation.HasAnyLocation or not itemLocation:HasAnyLocation() then
		return nil
	end
	if not C_Item.DoesItemExist(itemLocation) then
		return nil
	end

	return itemLocation
end

local function getFirstEmptyBankSlot(context)
	if not context or not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then
		return nil, nil
	end

	for _, bagID in ipairs(context.bagIDs or {}) do
		local slotCount = C_Container.GetContainerNumSlots(bagID) or 0
		for slotID = 1, slotCount do
			local info = C_Container.GetContainerItemInfo(bagID, slotID)
			if not (info and info.iconFileID) then
				return bagID, slotID
			end
		end
	end

	return nil, nil
end

local function receiveCursorItemIntoVisibleBank()
	local itemLocation = getCursorItemLocation()
	if not itemLocation or not C_Container or not C_Container.PickupContainerItem then
		return false
	end

	local context = getVisibleContext()
	local bankType = getBankTypeForContext(context)
	if bankType == nil then
		return false
	end

	if C_Bank and C_Bank.IsItemAllowedInBankType and not C_Bank.IsItemAllowedInBankType(bankType, itemLocation) then
		return false
	end

	local targetBagID, targetSlotID = getFirstEmptyBankSlot(context)
	if not targetBagID or not targetSlotID then
		return false
	end

	if bankType == ACCOUNT_BANK_TYPE and C_Item and C_Item.CanBeRefunded and C_Item.CanBeRefunded(itemLocation) then
		local targetItemLocation = ItemLocation and ItemLocation:CreateFromBagAndSlot(targetBagID, targetSlotID) or nil
		if StaticPopup_Show and Item and C_Item.GetItemGUID and C_Item.GetItemGUID(itemLocation) then
			StaticPopup_Show("ACCOUNT_BANK_DEPOSIT_NO_REFUND_CONFIRM", nil, nil, {
				itemToDeposit = Item:CreateFromItemGUID(C_Item.GetItemGUID(itemLocation)),
				targetItemLocation = targetItemLocation,
			})
			return true
		end
	end

	C_Container.PickupContainerItem(targetBagID, targetSlotID)
	scheduleUpdate(true, true, true, "DropReceiver")
	if Bags.functions and Bags.functions.RequestLayoutUpdate then
		Bags.functions.RequestLayoutUpdate(true, true)
	end
	return true
end

installFrameDropReceiver = function(frame, receiveMouseUp)
	if not frame or frame._bagsBankFrameDropReceiverInstalled then
		return
	end
	frame:EnableMouse(true)
	frame:SetScript("OnReceiveDrag", function()
		receiveCursorItemIntoVisibleBank()
	end)
	if receiveMouseUp and frame.HookScript then
		frame:HookScript("OnMouseUp", function(_, mouseButton)
			if mouseButton == "LeftButton" then
				receiveCursorItemIntoVisibleBank()
			end
		end)
	end
	frame._bagsBankFrameDropReceiverInstalled = true
end

local function toggleMoneyTransferPopup(dialogName, otherDialogName, context)
	local bankType = getBankTypeForContext(context)
	if bankType == nil then
		return
	end

	if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	end

	if otherDialogName then
		StaticPopup_Hide(otherDialogName)
	end

	if StaticPopup_Visible(dialogName) then
		StaticPopup_Hide(dialogName)
		return
	end

	StaticPopup_Show(dialogName, nil, nil, { bankType = bankType })
end

local function hasActiveSearchText()
	if not state.frame or not state.frame.SearchBox then
		return false
	end

	local searchText = state.frame.SearchBox:GetText()
	return searchText ~= nil and searchText ~= ""
end

local function isSectionCollapsed(sectionID)
	if not sectionID or hasActiveSearchText() then
		return false
	end

	return getCollapsedSectionsTable()[sectionID] == true
end

local function toggleSectionCollapsed(sectionID)
	if not sectionID then
		return
	end

	local collapsedSections = getCollapsedSectionsTable()
	if collapsedSections[sectionID] then
		collapsedSections[sectionID] = nil
	else
		collapsedSections[sectionID] = true
	end

	if Bags.functions.RequestBankLayoutUpdate then
		Bags.functions.RequestBankLayoutUpdate(true)
	end
end

local function getOverlayElements()
	return addon.GetOverlayElements and addon.GetOverlayElements() or {}
end

applyConfiguredFont = function(fontString, size, elementID)
	if addon.ApplyConfiguredFont then
		addon.ApplyConfiguredFont(fontString, size, elementID)
	elseif fontString and fontString.SetFont then
		fontString:SetFont(STANDARD_TEXT_FONT, size or 12, "OUTLINE")
	end
end

local function getResolvedTextAppearance(elementID)
	if addon.GetResolvedTextAppearance then
		return addon.GetResolvedTextAppearance(elementID)
	end

	return {
		size = 12,
		fontPath = STANDARD_TEXT_FONT,
		outlineFlags = "OUTLINE",
		signature = "fallback",
	}
end

getConfiguredBaseTextSize = function()
	local appearance = getResolvedTextAppearance()
	return tonumber(appearance and appearance.size) or 12
end

local function getMaxFrameHeight()
	local parentHeight = UIParent and UIParent:GetHeight() or nil
	local screenHeight = (parentHeight and parentHeight > 0) and parentHeight or 900
	return math.max(320, math.floor(screenHeight - MAX_FRAME_SCREEN_MARGIN))
end

local function getItemScale()
	if addon.GetItemScale then
		return addon.GetItemScale()
	end

	return 100
end

local function getButtonSize()
	local scale = getItemScale() / 100
	return math.max(24, math.floor((BUTTON_SIZE * scale) + 0.5))
end

local function getButtonSpacing()
	local scale = getItemScale() / 100
	return math.max(2, math.floor((BUTTON_SPACING * scale) + 0.5))
end

local function getContextSignature(context)
	return string.format("%s:%d", tostring(context and context.signature or ""), getItemScale())
end

local function updateScrollFrameLayout(contentWidth, contentHeight)
	if not state.frame or not state.scrollFrame or not state.content then
		return 1, 1
	end

	local buttonSize = getButtonSize()
	local buttonSpacing = getButtonSpacing()
	local fixedHeight = HEADER_HEIGHT + (FRAME_PADDING * 2)
	local maxContentHeight = math.max(MIN_SCROLL_CONTENT_HEIGHT, getMaxFrameHeight() - fixedHeight)
	local viewportHeight = math.max(1, math.min(contentHeight, maxContentHeight))
	local needsScroll = contentHeight > viewportHeight
	local reservedWidth = needsScroll and SCROLL_BAR_RESERVED_WIDTH or 0
	local frameWidth = math.max(MIN_FRAME_WIDTH, contentWidth + (FRAME_PADDING * 2) + reservedWidth)
	local viewportWidth = math.max(1, frameWidth - (FRAME_PADDING * 2) - reservedWidth)
	local resolvedContentWidth = math.max(contentWidth, viewportWidth)
	local resolvedContentHeight = math.max(1, contentHeight)
	local frameHeight = fixedHeight + viewportHeight
	local currentScroll = state.scrollFrame:GetVerticalScroll() or 0

	if state.scrollLayoutFrameWidth ~= frameWidth
		or state.scrollLayoutViewportWidth ~= viewportWidth
		or state.scrollLayoutViewportHeight ~= viewportHeight
		or state.scrollLayoutContentWidth ~= resolvedContentWidth
		or state.scrollLayoutContentHeight ~= resolvedContentHeight
		or state.scrollLayoutFrameHeight ~= frameHeight
	then
		state.scrollFrame:ClearAllPoints()
		state.scrollFrame:SetPoint("TOPLEFT", state.frame, "TOPLEFT", FRAME_PADDING, -(HEADER_HEIGHT + FRAME_PADDING))
		state.scrollFrame:SetSize(viewportWidth, viewportHeight)
		state.content:SetSize(resolvedContentWidth, resolvedContentHeight)
		state.scrollFrame:UpdateScrollChildRect()
		state.frame:SetSize(frameWidth, frameHeight)
		state.scrollLayoutFrameWidth = frameWidth
		state.scrollLayoutViewportWidth = viewportWidth
		state.scrollLayoutViewportHeight = viewportHeight
		state.scrollLayoutContentWidth = resolvedContentWidth
		state.scrollLayoutContentHeight = resolvedContentHeight
		state.scrollLayoutFrameHeight = frameHeight
	end

	if state.scrollFrame.ScrollBar then
		state.scrollFrame.ScrollBar.scrollStep = buttonSize + buttonSpacing
	end

	local scrollRange = state.scrollFrame:GetVerticalScrollRange() or 0
	local clampedScroll = math.min(math.max(0, currentScroll), scrollRange)
	if state.scrollFrame.ScrollBar then
		state.scrollFrame.ScrollBar:SetValue(clampedScroll)
	end

	return frameWidth, viewportHeight
end

local function handleScrollWheel(delta)
	if state.scrollFrame then
		ScrollFrameTemplate_OnMouseWheel(state.scrollFrame, delta)
	end
end

local function getTextAppearanceSignature(appearance)
	appearance = appearance or getResolvedTextAppearance()
	local baseSize = tonumber(appearance and appearance.size) or 12
	local overlaySize = tonumber(appearance and appearance.overlaySize) or baseSize
	return string.format(
		"%s:%s:%s:%s:%s:%s:%s",
		tostring(appearance and appearance.elementID or ""),
		tostring(appearance and appearance.fontPath or ""),
		tostring(baseSize),
		tostring(overlaySize),
		tostring(appearance and appearance.outline or ""),
		tostring(appearance and appearance.outlineFlags or ""),
		tostring(appearance and appearance.globalVersion or "")
	)
end

local function getItemButtonTextAppearanceSignature(appearance)
	local stackAppearance = getResolvedTextAppearance("stackCount")
	return getTextAppearanceSignature(appearance or getResolvedTextAppearance("overlays")) .. ":" .. getTextAppearanceSignature(stackAppearance)
end

local function getOverlayRuntimeConfig()
	if addon.GetOverlayRuntimeConfig then
		return addon.GetOverlayRuntimeConfig()
	end

	if not cachedOverlayRuntimeConfig then
		local runtime = {
			version = 0,
			entries = {},
			byID = {},
		}

		for _, definition in ipairs(getOverlayElements()) do
			local anchorID = addon.GetOverlayElementAnchor and addon.GetOverlayElementAnchor(definition.id) or definition.defaultAnchor
			local anchorInfo = addon.GetOverlayAnchorInfo and addon.GetOverlayAnchorInfo(anchorID)
			local entry = {
				id = definition.id,
				frameKey = definition.frameKey,
				enabled = addon.IsOverlayElementEnabled and addon.IsOverlayElementEnabled(definition.id) or definition.defaultEnabled ~= false,
				anchorInfo = anchorInfo,
			}
			runtime.entries[#runtime.entries + 1] = entry
			runtime.byID[definition.id] = entry
		end

		cachedOverlayRuntimeConfig = runtime
	end

	return cachedOverlayRuntimeConfig
end

local function applyConfiguredFrameFonts()
	if not state.frame then
		return
	end

	local appearance = getResolvedTextAppearance()
	local baseSize = tonumber(appearance and appearance.size) or 12
	if state.frame.Title then
		applyConfiguredFont(state.frame.Title, baseSize + 2)
	end
	if state.frame.SearchBox and state.frame.SearchBox.SetFont then
		applyConfiguredFont(state.frame.SearchBox, math.max(10, baseSize - 1))
		if state.frame.SearchBox.Instructions then
			applyConfiguredFont(state.frame.SearchBox.Instructions, math.max(10, baseSize - 1))
		end
	end
	if state.frame.ActionBar and state.frame.ActionBar.WarbandGoldText then
		applyConfiguredFont(state.frame.ActionBar.WarbandGoldText, math.max(10, baseSize - 1))
	end

	for _, header in ipairs(state.sectionHeaders or {}) do
		if header.Text then
			applyConfiguredFont(header.Text, nil, header._bagsTextElementID or "subcategoryHeader")
		end
	end

	if applyActiveSkin then
		applyActiveSkin()
	end
end

local function refreshActionBar(context)
	if not state.frame or not state.frame.ActionBar then
		return
	end

	local actionBar = state.frame.ActionBar
	local topRow = actionBar.TopRow
	local bottomRow = actionBar.BottomRow
	local depositButton = actionBar.DepositButton
	local purchaseTabButton = actionBar.PurchaseTabButton
	local includeReagentsCheckbox = actionBar.IncludeReagentsCheckbox
	local withdrawMoneyButton = actionBar.WithdrawMoneyButton
	local depositMoneyButton = actionBar.DepositMoneyButton
	local warbandGoldText = actionBar.WarbandGoldText
	local bankType = getBankTypeForContext(context)
	local lockedReason = getContextLockedReason(context)
	local isAccountBank = bankType == ACCOUNT_BANK_TYPE
	local moneyTransferSupported = doesContextSupportMoneyTransfer(context)

	if bankType == nil then
		actionBar:Hide()
		return
	end

	actionBar:Show()
	topRow:Show()

	depositButton:SetText(getContextDepositButtonText(context))
	sizeButtonToText(depositButton, DEPOSIT_BUTTON_WIDTH, 28)
	depositButton:SetEnabled(lockedReason == nil)
	depositButton:Show()

	local showPurchaseTabButton = lockedReason == nil and canPurchaseBankTab(bankType)
	if purchaseTabButton then
		purchaseTabButton:SetShown(showPurchaseTabButton)
		purchaseTabButton:SetAttribute("overrideBankType", bankType)
		if showPurchaseTabButton then
			purchaseTabButton:SetText(BANKSLOTPURCHASE or "Purchase")
			sizeButtonToText(purchaseTabButton, 132, 24)
		end
	end

	if isAccountBank then
		includeReagentsCheckbox.text = BANK_DEPOSIT_INCLUDE_REAGENTS_CHECKBOX_LABEL or "Include reagents"
		includeReagentsCheckbox.fontObject = GameFontHighlightSmall
		includeReagentsCheckbox.textWidth = 180
		includeReagentsCheckbox.maxTextLines = 2
		includeReagentsCheckbox:SetEnabledState(lockedReason == nil)
		includeReagentsCheckbox:SetShown(lockedReason == nil)
		if includeReagentsCheckbox.Text then
			includeReagentsCheckbox.Text:SetText(includeReagentsCheckbox.text)
		end
	else
		includeReagentsCheckbox:SetEnabledState(false)
		includeReagentsCheckbox:Hide()
	end

	local showBottomRow = isAccountBank
	bottomRow:SetShown(showBottomRow)

	if showBottomRow then
		warbandGoldText:SetText(string.format(
			"%s: %s",
			L["warbandGold"] or "Warband gold",
			formatMoneyString(getWarbandMoneyAmount())
		))
		warbandGoldText:Show()
	else
		warbandGoldText:SetText("")
		warbandGoldText:Hide()
	end

	local showMoneyButtons = showBottomRow and moneyTransferSupported and lockedReason == nil
	withdrawMoneyButton:SetShown(showMoneyButtons)
	depositMoneyButton:SetShown(showMoneyButtons)
	if showMoneyButtons then
		sizeButtonToText(withdrawMoneyButton, MONEY_BUTTON_WIDTH, 24)
		sizeButtonToText(depositMoneyButton, MONEY_BUTTON_WIDTH, 24)
		withdrawMoneyButton:SetEnabled(C_Bank and C_Bank.CanWithdrawMoney and C_Bank.CanWithdrawMoney(bankType) or false)
		depositMoneyButton:SetEnabled(C_Bank and C_Bank.CanDepositMoney and C_Bank.CanDepositMoney(bankType) or false)
	end
end

local function applyConfiguredItemButtonFonts(button, appearance, signature)
	if not button then
		return
	end

	appearance = appearance or getResolvedTextAppearance("overlays")
	local stackAppearance = getResolvedTextAppearance("stackCount")
	local overlayBaseSize = tonumber(appearance and appearance.size) or 12
	local stackBaseSize = tonumber(stackAppearance and stackAppearance.size) or overlayBaseSize
	signature = signature or getItemButtonTextAppearanceSignature(appearance)
	if button._bagsWarbandFontSignature == signature then
		return
	end

	button._bagsWarbandFontSignature = signature
	if button.ItemLevelText then
		applyConfiguredFont(button.ItemLevelText, overlayBaseSize, "overlays")
		button.ItemLevelText:SetJustifyH("RIGHT")
	end
	if button.ItemUpgradeText then
		applyConfiguredFont(button.ItemUpgradeText, math.max(8, overlayBaseSize - 2), "overlays")
		button.ItemUpgradeText:SetJustifyH("RIGHT")
	end
	if button.BindStatusText then
		applyConfiguredFont(button.BindStatusText, math.max(8, overlayBaseSize - 2), "overlays")
		button.BindStatusText:SetJustifyH("RIGHT")
	end
	if button.EquipmentSetText then
		applyConfiguredFont(button.EquipmentSetText, math.max(8, overlayBaseSize - 2), "overlays")
		button.EquipmentSetText:SetJustifyH("LEFT")
	end
	if button.Count then
		applyConfiguredFont(button.Count, stackBaseSize, "stackCount")
	end
end

local function applyConfiguredOverlayAnchors(button, overlayRuntime)
	if not button then
		return
	end

	overlayRuntime = overlayRuntime or getOverlayRuntimeConfig()
	local version = overlayRuntime and overlayRuntime.version or 0
	if button._bagsWarbandOverlayVersion == version then
		return
	end

	button._bagsWarbandOverlayVersion = version
	for _, entry in ipairs((overlayRuntime and overlayRuntime.entries) or {}) do
		local region = entry.frameKey and button[entry.frameKey]
		local anchorInfo = entry.anchorInfo
		if region and anchorInfo then
			region:ClearAllPoints()
			region:SetPoint(anchorInfo.point, button, anchorInfo.relativePoint, anchorInfo.x, anchorInfo.y)
			if region.SetJustifyH and anchorInfo.justifyH then
				region:SetJustifyH(anchorInfo.justifyH)
			end
			if region.SetJustifyV and anchorInfo.justifyV then
				region:SetJustifyV(anchorInfo.justifyV)
			end
		end
		region = entry.textFrameKey and button[entry.textFrameKey]
		if region and anchorInfo then
			region:ClearAllPoints()
			region:SetPoint(anchorInfo.point, button, anchorInfo.relativePoint, anchorInfo.x, anchorInfo.y)
			if region.SetJustifyH and anchorInfo.justifyH then
				region:SetJustifyH(anchorInfo.justifyH)
			end
			if region.SetJustifyV and anchorInfo.justifyV then
				region:SetJustifyV(anchorInfo.justifyV)
			end
		end
	end
end

local function shouldDisplayItemLevel(itemRef)
	if not itemRef then
		return false
	end

	local cacheKey = tostring(itemRef)
	local cached = itemLevelEligibilityCache[cacheKey]
	if cached ~= nil then
		return cached
	end

	local equipLoc = select(4, GetItemInfoInstant(itemRef))
	local shouldDisplay = equipLoc ~= nil and not IGNORED_ITEM_LEVEL_EQUIP_LOCS[equipLoc]
	itemLevelEligibilityCache[cacheKey] = shouldDisplay
	return shouldDisplay
end

local function hideButtonOverlayText(button, textRegion, cacheField, hiddenKey)
	if button[cacheField] == hiddenKey then
		return
	end

	textRegion:SetText("")
	textRegion:Hide()
	button[cacheField] = hiddenKey
end

local function isKeystoneItem(itemID)
	return itemID and C_Item and C_Item.IsItemKeystoneByID and C_Item.IsItemKeystoneByID(itemID) or false
end

local function getKeystoneLevelFromItemLink(itemLink)
	if type(itemLink) ~= "string" then
		return nil
	end

	return tonumber(itemLink:match("keystone:[^:]*:[^:]*:(%d+)"))
end

local function getKeystoneLevelTextColor(level)
	if not level or not C_ChallengeMode or not C_ChallengeMode.GetKeystoneLevelRarityColor then
		return nil
	end

	local color = C_ChallengeMode.GetKeystoneLevelRarityColor(level)
	if type(color) ~= "table" then
		return nil
	end

	return color.r or color[1], color.g or color[2], color.b or color[3]
end

local function isRuleHearthstoneItem(itemID)
	itemID = tonumber(itemID)
	return itemID ~= nil and HEARTHSTONE_ITEM_IDS[itemID] == true or false
end

local function updateJunkCoinIcon(button, quality)
	if not button or not button.JunkIcon then
		return
	end

	if quality == ITEM_QUALITY_POOR then
		button.JunkIcon:SetAtlas("bags-junkcoin", true)
		button.JunkIcon:Show()
	else
		button.JunkIcon:Hide()
	end
end

local function updateItemLevelText(button, itemLink, itemID, quality, overlayRuntime)
	if not button or not button.ItemLevelText then
		return
	end

	local text = button.ItemLevelText
	local overlayEntry = overlayRuntime and overlayRuntime.byID and overlayRuntime.byID.itemLevel or nil
	local overlayVersion = overlayRuntime and overlayRuntime.version or 0
	local itemRef = itemLink or itemID
	local evalKey = string.format("%s:%s:%s", tostring(itemRef or 0), tostring(quality or 0), tostring(overlayVersion))

	if not (overlayEntry and overlayEntry.enabled) then
		hideButtonOverlayText(button, text, "_bagsWarbandItemLevelEvalKey", "hidden:" .. evalKey)
		return
	end

	local keystoneLevel = isKeystoneItem(itemID) and getKeystoneLevelFromItemLink(itemLink) or nil
	if keystoneLevel then
		local keystoneEvalKey = "keystone:" .. evalKey
		if button._bagsWarbandItemLevelEvalKey == keystoneEvalKey then
			return
		end

		text:SetText(addon.FormatTextElement and addon.FormatTextElement("overlays", tostring(keystoneLevel)) or keystoneLevel)
		local r, g, b = getKeystoneLevelTextColor(keystoneLevel)
		if r then
			text:SetTextColor(r, g, b)
		else
			text:SetTextColor(1, 1, 1)
		end
		text:Show()
		button._bagsWarbandItemLevelEvalKey = keystoneEvalKey
		return
	end

	if not shouldDisplayItemLevel(itemRef) then
		hideButtonOverlayText(button, text, "_bagsWarbandItemLevelEvalKey", "ignored:" .. evalKey)
		return
	end

	if button._bagsWarbandItemLevelEvalKey == evalKey then
		return
	end

	local itemLocation = ItemLocation:CreateFromBagAndSlot(button:GetBagID(), button:GetID())
	local itemLevel
	if itemLocation and C_Item.DoesItemExist(itemLocation) then
		itemLevel = C_Item.GetCurrentItemLevel(itemLocation)
	end
	if (not itemLevel or itemLevel <= 0) and itemRef and C_Item.GetDetailedItemLevelInfo then
		itemLevel = C_Item.GetDetailedItemLevelInfo(itemRef)
	end
	itemLevel = tonumber(itemLevel)
	if not itemLevel or itemLevel <= 1 then
		button._bagsWarbandItemLevelEvalKey = nil
		text:SetText("")
		text:Hide()
		return
	end

	text:SetText(addon.FormatTextElement and addon.FormatTextElement("overlays", tostring(itemLevel)) or itemLevel)
	if overlayEntry and overlayEntry.colorMode == "custom" and type(overlayEntry.customColor) == "table" then
		text:SetTextColor(
			tonumber(overlayEntry.customColor[1]) or 1,
			tonumber(overlayEntry.customColor[2]) or 1,
			tonumber(overlayEntry.customColor[3]) or 1
		)
	elseif quality and quality >= MIN_ITEM_LEVEL_COLOR_QUALITY and C_Item.GetItemQualityColor then
		local r, g, b = C_Item.GetItemQualityColor(quality)
		if r then
			text:SetTextColor(r, g, b)
		else
			text:SetTextColor(1, 1, 1)
		end
	else
		text:SetTextColor(1, 1, 1)
	end
	text:Show()
	button._bagsWarbandItemLevelEvalKey = evalKey
end

local function updateItemUpgradeText(button, itemLink, itemID, overlayRuntime)
	if not button or not button.ItemUpgradeText then
		return
	end

	local text = button.ItemUpgradeText
	local overlayEntry = overlayRuntime and overlayRuntime.byID and overlayRuntime.byID.upgradeTrack or nil
	local overlayVersion = overlayRuntime and overlayRuntime.version or 0
	local itemRef = itemLink or itemID
	local evalKey = string.format("%s:%s", tostring(itemRef or 0), tostring(overlayVersion))

	if not (overlayEntry and overlayEntry.enabled) then
		hideButtonOverlayText(button, text, "_bagsWarbandItemUpgradeEvalKey", "hidden:" .. evalKey)
		return
	end

	if not itemRef or not addon.GetItemUpgradeInfoForItem then
		hideButtonOverlayText(button, text, "_bagsWarbandItemUpgradeEvalKey", "empty:" .. evalKey)
		return
	end

	if button._bagsWarbandItemUpgradeEvalKey == evalKey then
		return
	end

	local upgradeInfo = addon.GetItemUpgradeInfoForItem(itemRef)
	if not upgradeInfo or not upgradeInfo.displayText or upgradeInfo.displayText == "" then
		button._bagsWarbandItemUpgradeEvalKey = nil
		text:SetText("")
		text:Hide()
		return
	end
	if addon.IsUpgradeTrackOverlayTrackEnabled and not addon.IsUpgradeTrackOverlayTrackEnabled(upgradeInfo.key) then
		hideButtonOverlayText(button, text, "_bagsWarbandItemUpgradeEvalKey", "filtered:" .. evalKey .. ":" .. tostring(upgradeInfo.key))
		return
	end

	text:SetText(addon.FormatTextElement and addon.FormatTextElement("overlays", upgradeInfo.displayText) or upgradeInfo.displayText)
	if addon.GetUpgradeTrackColor then
		local r, g, b = addon.GetUpgradeTrackColor(upgradeInfo.key)
		text:SetTextColor(r or 1, g or 1, b or 1)
	else
		text:SetTextColor(1, 1, 1)
	end
	text:Show()
	button._bagsWarbandItemUpgradeEvalKey = evalKey
end

local function getTooltipOverlayBindStatus(bagID, slotID, info)
	if not GET_BAG_ITEM_TOOLTIP or bagID == nil or slotID == nil then
		return nil
	end

	local cacheKey = tostring(bagID) .. ":" .. tostring(slotID)
	local itemLink = info and info.hyperlink or nil
	local itemID = info and info.itemID or nil
	local isBound = info and info.isBound or false
	local cached = state.overlayBindStatusCache and state.overlayBindStatusCache[cacheKey] or nil
	if cached
		and cached.itemLink == itemLink
		and cached.itemID == itemID
		and cached.isBound == isBound
	then
		return cached.status or nil
	end

	local status
	local tooltipData = GET_BAG_ITEM_TOOLTIP(bagID, slotID)
	for _, line in ipairs((tooltipData and tooltipData.lines) or {}) do
		local text = line and line.leftText or nil
		if line and line.type == 20 and text then
			if text == ITEM_BIND_ON_EQUIP then
				status = "BoE"
				break
			elseif text == ITEM_ACCOUNTBOUND_UNTIL_EQUIP or text == ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP then
				status = "WuE"
				break
			elseif text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_ACCOUNT or text == ITEM_BIND_TO_BNETACCOUNT then
				status = "WB"
				break
			end
		end
	end

	state.overlayBindStatusCache[cacheKey] = {
		itemLink = itemLink,
		itemID = itemID,
		isBound = isBound,
		status = status or false,
	}

	return status
end

local function getBindStatusOverlayColor(status)
	if status == "BoE" then
		return 0.38, 0.82, 1
	elseif status == "WB" then
		return 0.4, 1, 0.72
	elseif status == "WuE" then
		return 0.8, 1, 0.45
	end
	return 1, 1, 1
end

local function updateBindStatusOverlay(button, bagID, slotID, info, overlayRuntime)
	if not button or not button.BindStatusText then
		return
	end

	local text = button.BindStatusText
	local overlayEntry = overlayRuntime and overlayRuntime.byID and overlayRuntime.byID.bindStatus or nil
	local overlayVersion = overlayRuntime and overlayRuntime.version or 0
	local itemLink = info and info.hyperlink or nil
	local itemID = info and info.itemID or nil
	local evalKey = string.format("%s:%s:%s:%s", tostring(bagID), tostring(slotID), tostring(itemLink or itemID or 0), tostring(overlayVersion))

	if not (overlayEntry and overlayEntry.enabled) then
		hideButtonOverlayText(button, text, "_bagsWarbandBindStatusEvalKey", "hidden:" .. evalKey)
		return
	end

	if not itemLink and not itemID then
		hideButtonOverlayText(button, text, "_bagsWarbandBindStatusEvalKey", "empty:" .. evalKey)
		return
	end

	local status = getTooltipOverlayBindStatus(bagID, slotID, info)
	if not status then
		hideButtonOverlayText(button, text, "_bagsWarbandBindStatusEvalKey", "none:" .. evalKey)
		return
	end

	local statusEvalKey = status .. ":" .. evalKey
	if button._bagsWarbandBindStatusEvalKey == statusEvalKey then
		return
	end

	text:SetText(addon.FormatTextElement and addon.FormatTextElement("overlays", status) or status)
	text:SetTextColor(getBindStatusOverlayColor(status))
	text:Show()
	button._bagsWarbandBindStatusEvalKey = statusEvalKey
end

local function hideButtonOverlayRegion(button, region, cacheField, hiddenKey)
	if button[cacheField] == hiddenKey then
		return
	end

	region:Hide()
	button[cacheField] = hiddenKey
end

local function getEquipmentSetOverlayTexture(bagID, slotID)
	local equipmentSetInfo = addon.GetEquipmentSetOverlayInfo and addon.GetEquipmentSetOverlayInfo(bagID, slotID) or nil
	if not equipmentSetInfo then
		return nil
	end

	return equipmentSetInfo.texture or EQUIPMENT_SET_OVERLAY_FALLBACK_TEXTURE, equipmentSetInfo
end

local function updateEquipmentSetOverlay(button, bagID, slotID, info, overlayRuntime)
	if not button or not button.EquipmentSetIcon or not button.EquipmentSetText then
		return
	end

	local icon = button.EquipmentSetIcon
	local text = button.EquipmentSetText
	local overlayEntry = overlayRuntime and overlayRuntime.byID and overlayRuntime.byID.equipmentSet or nil
	local overlayVersion = overlayRuntime and overlayRuntime.version or 0
	local displayMode = overlayEntry and overlayEntry.displayMode or "icon"
	local itemLink = info and info.hyperlink or nil
	local itemID = info and info.itemID or nil
	local evalKey = string.format("%s:%s:%s:%s:%s", tostring(bagID), tostring(slotID), tostring(itemLink or itemID or 0), tostring(overlayVersion), tostring(displayMode))

	if not (overlayEntry and overlayEntry.enabled) then
		hideButtonOverlayRegion(button, icon, "_bagsWarbandEquipmentSetEvalKey", "hidden:" .. evalKey)
		text:SetText("")
		text:Hide()
		return
	end

	if not itemLink and not itemID then
		hideButtonOverlayRegion(button, icon, "_bagsWarbandEquipmentSetEvalKey", "empty:" .. evalKey)
		text:SetText("")
		text:Hide()
		return
	end

	local texture, equipmentSetInfo = getEquipmentSetOverlayTexture(bagID, slotID)
	if not texture then
		hideButtonOverlayRegion(button, icon, "_bagsWarbandEquipmentSetEvalKey", "none:" .. evalKey)
		text:SetText("")
		text:Hide()
		return
	end

	local setEvalKey = tostring(texture) .. ":" .. tostring(equipmentSetInfo and equipmentSetInfo.colorKey or "") .. ":" .. evalKey
	if button._bagsWarbandEquipmentSetEvalKey == setEvalKey then
		return
	end

	if displayMode == "text" then
		icon:Hide()
		text:SetText(addon.FormatTextElement and addon.FormatTextElement("overlays", "SET") or "SET")
		text:SetTextColor(
			(equipmentSetInfo and equipmentSetInfo.r) or 0.36,
			(equipmentSetInfo and equipmentSetInfo.g) or 0.78,
			(equipmentSetInfo and equipmentSetInfo.b) or 1
		)
		text:Show()
	else
		text:SetText("")
		text:Hide()
		icon:SetTexture(texture)
		icon:SetSize(14, 14)
		icon:SetVertexColor(1, 1, 1)
		icon:Show()
	end
	button._bagsWarbandEquipmentSetEvalKey = setEvalKey
end

getCachedRuleItemInfo = function(itemRef)
	if not itemRef then
		return nil
	end

	local cacheKey = itemRef
	local cachedInfo = state.itemRuleDataCache[cacheKey]
	if cachedInfo and cachedInfo.loaded then
		return cachedInfo
	end

	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent, itemDescription
	if C_Item and C_Item.GetItemInfo then
		itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent, itemDescription = C_Item.GetItemInfo(itemRef)
	else
		itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent, itemDescription = GetItemInfo(itemRef)
	end

	cachedInfo = cachedInfo or {}
	cachedInfo.loaded = itemName ~= nil
	cachedInfo.itemName = itemName
	cachedInfo.itemLink = itemLink
	cachedInfo.itemQuality = itemQuality
	cachedInfo.itemLevel = itemLevel
	cachedInfo.itemMinLevel = itemMinLevel
	cachedInfo.itemType = itemType
	cachedInfo.itemSubType = itemSubType
	cachedInfo.itemStackCount = itemStackCount
	cachedInfo.itemEquipLoc = itemEquipLoc
	cachedInfo.itemTexture = itemTexture
	cachedInfo.sellPrice = sellPrice
	cachedInfo.classID = classID
	cachedInfo.subclassID = subclassID
	cachedInfo.bindType = bindType
	cachedInfo.expansionID = expansionID
	cachedInfo.setID = setID
	cachedInfo.isCraftingReagent = isCraftingReagent
	cachedInfo.itemDescription = itemDescription
	state.itemRuleDataCache[cacheKey] = cachedInfo

	return cachedInfo
end

local function getCurrentCategoryRulesRevision()
	return addon.GetCategoryRulesRevision and addon.GetCategoryRulesRevision() or 0
end

local function doesRuleUsageDependOnPlayerState(usage)
	return usage and (usage.recommendedForClass or usage.recommendedForSpec or usage.isUpgrade or usage.equippedAverageItemLevel) and true or false
end

local function bumpPlayerRuleRevision()
	state.playerRuleRevision = (state.playerRuleRevision or 0) + 1
end

local function getSlotCategoryCacheBucket(bagID, create)
	if bagID == nil then
		return nil
	end

	local bucket = state.slotCategoryCache[bagID]
	if not bucket and create then
		bucket = {}
		state.slotCategoryCache[bagID] = bucket
	end

	return bucket
end

local function getSlotCategoryCacheEntry(bagID, slotID)
	local bucket = getSlotCategoryCacheBucket(bagID, false)
	return bucket and bucket[slotID] or nil
end

local function setSlotCategoryCacheEntry(bagID, slotID, entry)
	local bucket = getSlotCategoryCacheBucket(bagID, true)
	bucket[slotID] = entry
end

local function clearSlotCategoryCacheEntry(bagID, slotID)
	local bucket = getSlotCategoryCacheBucket(bagID, false)
	if bucket then
		bucket[slotID] = nil
	end
end

local function isSlotCategoryCacheEntryValid(entry, bagID, slotID, info, questInfo, settings, ruleRuntimeContext, hasCustomCategories)
	if not entry or not entry.stable then
		return false
	end

	local showCategories = not not (settings and settings.showCategories)
	local combineDuplicates = not not (settings and settings.combineUnstackableItems)
	local itemLink = info and info.hyperlink or false
	local itemID = info and info.itemID or false
	local quality = info and info.quality or false
	local stackCount = info and info.stackCount or false
	local isBound = info and info.isBound or false
	local questID = questInfo and questInfo.questID or false
	local isQuestItem = questInfo and questInfo.isQuestItem or false
	local isNewItem = isOpenSessionNewItem(bagID, slotID, info)
	local categoryRulesRevision = ruleRuntimeContext and ruleRuntimeContext.categoryRulesRevision or 0
	local playerRuleRevision = ruleRuntimeContext and ruleRuntimeContext.playerRuleRevision or 0

	return entry.showCategories == showCategories
		and entry.combineDuplicates == combineDuplicates
		and entry.hasCustomCategories == hasCustomCategories
		and entry.categoryRulesRevision == categoryRulesRevision
		and entry.playerRuleRevision == playerRuleRevision
		and entry.itemLink == itemLink
		and entry.itemID == itemID
		and entry.quality == quality
		and entry.stackCount == stackCount
		and entry.isBound == isBound
		and entry.questID == questID
		and entry.isQuestItem == isQuestItem
		and entry.isNewItem == isNewItem
end

local function getCachedResolvedCategoryData(bagID, slotID, info, questInfo, settings, ruleRuntimeContext, hasCustomCategories)
	local entry = getSlotCategoryCacheEntry(bagID, slotID)
	if not isSlotCategoryCacheEntryValid(entry, bagID, slotID, info, questInfo, settings, ruleRuntimeContext, hasCustomCategories) then
		return nil
	end

	return entry.sectionID, entry.collapseRef ~= false and entry.collapseRef or nil
end

local function updateResolvedCategoryCache(
	bagID,
	slotID,
	info,
	questInfo,
	settings,
	ruleRuntimeContext,
	hasCustomCategories,
	sectionID,
	collapseRef,
	stable
)
	if not stable then
		clearSlotCategoryCacheEntry(bagID, slotID)
		return
	end

	setSlotCategoryCacheEntry(bagID, slotID, {
		stable = true,
		showCategories = not not (settings and settings.showCategories),
		combineDuplicates = not not (settings and settings.combineUnstackableItems),
		hasCustomCategories = hasCustomCategories,
		categoryRulesRevision = ruleRuntimeContext and ruleRuntimeContext.categoryRulesRevision or 0,
		playerRuleRevision = ruleRuntimeContext and ruleRuntimeContext.playerRuleRevision or 0,
		itemLink = info and info.hyperlink or false,
		itemID = info and info.itemID or false,
		quality = info and info.quality or false,
		stackCount = info and info.stackCount or false,
		isBound = info and info.isBound or false,
		questID = questInfo and questInfo.questID or false,
		isQuestItem = questInfo and questInfo.isQuestItem or false,
		isNewItem = isOpenSessionNewItem(bagID, slotID, info),
		sectionID = sectionID,
		collapseRef = collapseRef or false,
	})
end

local function createRuleRuntimeContext(usage)
	local hasPlayerStateUsage = doesRuleUsageDependOnPlayerState(usage)
	local runtimeContext = {
		usage = usage or {},
		hasUsage = usage and next(usage) ~= nil or false,
		hasPlayerStateUsage = hasPlayerStateUsage,
		equippedItemLevels = {},
		equippedItemEquipLocs = {},
		tooltipBindTypes = {},
		tooltipItemFlags = {},
		persistentTooltipBindTypes = state.tooltipBindTypeCache,
		persistentTooltipItemFlags = state.tooltipDerivedItemFlagsCache,
		recommendationCache = {},
		upgradeTrackCache = {},
		categoryRulesRevision = getCurrentCategoryRulesRevision(),
		playerRuleRevision = hasPlayerStateUsage and (state.playerRuleRevision or 0) or 0,
		itemContext = {},
	}

	if hasPlayerStateUsage then
		local _, classToken, classID = UnitClass("player")
		runtimeContext.playerClassToken = classToken
		runtimeContext.playerClassID = classID

		local specIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
		runtimeContext.playerSpecIndex = specIndex
		if specIndex and specIndex > 0 and C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
			runtimeContext.playerSpecID = C_SpecializationInfo.GetSpecializationInfo(specIndex)
		end
	end

	return runtimeContext
end

function Bags.functions.GetRuleEquippedAverageItemLevel(runtimeContext)
	if not runtimeContext then
		return nil
	end

	local equippedItemLevel = runtimeContext.equippedAverageItemLevel
	if equippedItemLevel == nil then
		if type(GetAverageItemLevel) == "function" then
			equippedItemLevel = select(2, GetAverageItemLevel())
		end

		equippedItemLevel = tonumber(equippedItemLevel)
		runtimeContext.equippedAverageItemLevel = equippedItemLevel and equippedItemLevel > 0 and equippedItemLevel or false
		equippedItemLevel = runtimeContext.equippedAverageItemLevel
	end

	if not equippedItemLevel then
		return nil
	end

	return equippedItemLevel
end

local function getEquippedItemLevel(runtimeContext, inventorySlot)
	if not runtimeContext or not inventorySlot then
		return 0
	end

	local cachedLevel = runtimeContext.equippedItemLevels[inventorySlot]
	if cachedLevel ~= nil then
		return cachedLevel
	end

	local equippedLevel = 0
	local equippedLocation = ItemLocation and ItemLocation:CreateFromEquipmentSlot(inventorySlot) or nil
	if equippedLocation and C_Item and C_Item.DoesItemExist and C_Item.DoesItemExist(equippedLocation) then
		equippedLevel = C_Item.GetCurrentItemLevel and C_Item.GetCurrentItemLevel(equippedLocation) or 0
	end

	if not equippedLevel or equippedLevel <= 0 then
		local equippedLink = GetInventoryItemLink("player", inventorySlot)
		equippedLevel = equippedLink and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(equippedLink) or 0
	end

	equippedLevel = tonumber(equippedLevel) or 0
	runtimeContext.equippedItemLevels[inventorySlot] = equippedLevel
	return equippedLevel
end

local function getEquippedItemEquipLoc(runtimeContext, inventorySlot)
	if not runtimeContext or not inventorySlot then
		return nil
	end

	local cachedEquipLoc = runtimeContext.equippedItemEquipLocs[inventorySlot]
	if cachedEquipLoc ~= nil then
		return cachedEquipLoc or nil
	end

	local equippedRef = GetInventoryItemLink("player", inventorySlot) or GetInventoryItemID("player", inventorySlot)
	local equipLoc = equippedRef and select(4, GetItemInfoInstant(equippedRef)) or nil
	runtimeContext.equippedItemEquipLocs[inventorySlot] = equipLoc or false
	return equipLoc
end

local function isTwoHandWeaponEquipLoc(equipLoc)
	return equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT"
end

local function isOneHandWeaponEquipLoc(equipLoc)
	return equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_WEAPONMAINHAND"
end

local function getTooltipResolvedBindType(bagID, slotID, info, runtimeContext)
	if not runtimeContext or not GET_BAG_ITEM_TOOLTIP or bagID == nil or slotID == nil then
		return nil
	end

	local runtimeBagCache = runtimeContext.tooltipBindTypes[bagID]
	local cachedBindType = runtimeBagCache and runtimeBagCache[slotID]
	if cachedBindType ~= nil then
		return cachedBindType or nil
	end

	local itemLink = info and info.hyperlink or false
	local itemID = info and info.itemID or false
	local isBound = info and info.isBound or false
	local persistentCache = runtimeContext.persistentTooltipBindTypes
	local persistentBagCache = persistentCache and persistentCache[bagID]
	local persistentEntry = persistentBagCache and persistentBagCache[slotID]
	if persistentEntry
		and persistentEntry.itemLink == itemLink
		and persistentEntry.itemID == itemID
		and persistentEntry.isBound == isBound
	then
		local persistentBindType = persistentEntry.bindType
		if not runtimeBagCache then
			runtimeBagCache = {}
			runtimeContext.tooltipBindTypes[bagID] = runtimeBagCache
		end
		runtimeBagCache[slotID] = persistentBindType or false
		return persistentBindType or nil
	end

	local resolvedBindType
	local tooltipData = GET_BAG_ITEM_TOOLTIP(bagID, slotID)
	local lines = tooltipData and tooltipData.lines
	if lines then
		for _, line in ipairs(lines) do
			if line.type == 20 then
				local text = line.leftText
				if text == ITEM_BIND_ON_PICKUP then
					resolvedBindType = 1
				elseif text == ITEM_BIND_ON_EQUIP then
					resolvedBindType = 2
				elseif text == ITEM_BIND_ON_USE then
					resolvedBindType = 3
				elseif text == ITEM_BIND_QUEST then
					resolvedBindType = 4
				elseif text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_ACCOUNT then
					resolvedBindType = 7
				elseif text == ITEM_BIND_TO_BNETACCOUNT then
					resolvedBindType = 8
				elseif text == ITEM_ACCOUNTBOUND_UNTIL_EQUIP or text == ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP then
					resolvedBindType = 9
				end

				if resolvedBindType ~= nil then
					break
				end
			end
		end
	end

	if not runtimeBagCache then
		runtimeBagCache = {}
		runtimeContext.tooltipBindTypes[bagID] = runtimeBagCache
	end
	runtimeBagCache[slotID] = resolvedBindType or false
	if persistentCache then
		if not persistentBagCache then
			persistentBagCache = {}
			persistentCache[bagID] = persistentBagCache
		end
		persistentBagCache[slotID] = {
			itemLink = itemLink,
			itemID = itemID,
			isBound = isBound,
			bindType = resolvedBindType or false,
		}
	end
	return resolvedBindType
end

local function getTooltipDerivedItemFlags(bagID, slotID, info, runtimeContext)
	if not GET_BAG_ITEM_TOOLTIP or bagID == nil or slotID == nil then
		return nil
	end

	local itemLink = info and info.hyperlink or false
	local itemID = info and info.itemID or false
	local stackCount = info and info.stackCount or false
	local isBound = info and info.isBound or false
	local quality = info and info.quality or false
	local iconFileID = info and info.iconFileID or false
	if not iconFileID and not itemLink and not itemID then
		return nil
	end

	local runtimeCache = runtimeContext and runtimeContext.tooltipItemFlags or nil
	local runtimeBagCache = runtimeCache and runtimeCache[bagID] or nil
	local cached = runtimeBagCache and runtimeBagCache[slotID] or nil
	if cached
		and cached.itemLink == itemLink
		and cached.itemID == itemID
		and cached.stackCount == stackCount
		and cached.isBound == isBound
		and cached.quality == quality
		and cached.iconFileID == iconFileID
	then
		return cached
	end

	local persistentCache = (runtimeContext and runtimeContext.persistentTooltipItemFlags) or state.tooltipDerivedItemFlagsCache
	local persistentBagCache = persistentCache and persistentCache[bagID] or nil
	local persistentEntry = persistentBagCache and persistentBagCache[slotID] or nil
	if persistentEntry
		and persistentEntry.itemLink == itemLink
		and persistentEntry.itemID == itemID
		and persistentEntry.stackCount == stackCount
		and persistentEntry.isBound == isBound
		and persistentEntry.quality == quality
		and persistentEntry.iconFileID == iconFileID
	then
		if runtimeCache then
			if not runtimeBagCache then
				runtimeBagCache = {}
				runtimeCache[bagID] = runtimeBagCache
			end
			runtimeBagCache[slotID] = persistentEntry
		end
		return persistentEntry
	end

	local tooltipData = GET_BAG_ITEM_TOOLTIP(bagID, slotID)
	local lines = tooltipData and tooltipData.lines
	if not lines then
		return nil
	end

	local flags = persistentEntry or {}
	flags.itemLink = itemLink
	flags.itemID = itemID
	flags.stackCount = stackCount
	flags.isBound = isBound
	flags.quality = quality
	flags.iconFileID = iconFileID
	flags.isToy = false
	flags.isKnownToy = false
	flags.isTransmogSet = false
	flags.isPvpItem = false
	flags.hasUsageRequirement = false

	local toyText = _G.TOY
	local knownText = ITEM_SPELL_KNOWN
	local hasToyLine = false
	local hasKnownLine = false
	local function isUnusableLineColor(line)
		local color = line and line.leftColor
		if type(color) ~= "table" then return false end
		local r = color and (color.r or color[1])
		local g = color and (color.g or color[2])
		local b = color and (color.b or color[3])
		return r and g and b and r >= 0.9 and g <= 0.25 and b <= 0.25
	end
	for index = 1, #lines do
		local line = lines[index]
		if line then
			local lineType = line.type
			if lineType == LEARN_TRANSMOG_SET_TOOLTIP_LINE_TYPE then
				flags.isTransmogSet = true
			elseif toyText and lineType == TOY_TOOLTIP_LINE_TYPE and line.leftText == toyText then
				hasToyLine = true
			elseif state.pvpItemTooltipPattern and lineType == 0 and line.leftText and line.leftText:match(state.pvpItemTooltipPattern) then
				flags.isPvpItem = true
			elseif lineType == KNOWN_SPELL_TOOLTIP_LINE_TYPE then
				if knownText and line.leftText == knownText then
					hasKnownLine = true
				elseif isUnusableLineColor(line) then
					flags.hasUsageRequirement = true
				end
			end
		end
	end

	flags.isToy = hasToyLine
	flags.isKnownToy = hasToyLine and hasKnownLine or false

	if persistentCache then
		if not persistentBagCache then
			persistentBagCache = {}
			persistentCache[bagID] = persistentBagCache
		end
		persistentBagCache[slotID] = flags
	end
	if runtimeCache then
		if not runtimeBagCache then
			runtimeBagCache = {}
			runtimeCache[bagID] = runtimeBagCache
		end
		runtimeBagCache[slotID] = flags
	end

	return flags
end

local function getUpgradeComparisonSlots(equipLoc, runtimeContext)
	if not equipLoc then
		return nil, nil
	end

	local mainhandSlot = INVSLOT_MAINHAND or 16
	local offhandSlot = INVSLOT_OFFHAND or 17

	if equipLoc == "INVTYPE_2HWEAPON" then
		local mainhandEquipLoc = getEquippedItemEquipLoc(runtimeContext, mainhandSlot)
		local offhandEquipLoc = getEquippedItemEquipLoc(runtimeContext, offhandSlot)
		local offhandOccupied = (offhandEquipLoc and offhandEquipLoc ~= "") or getEquippedItemLevel(runtimeContext, offhandSlot) > 0
		local isDualTwoHandLoadout = isTwoHandWeaponEquipLoc(mainhandEquipLoc)
			and isTwoHandWeaponEquipLoc(offhandEquipLoc)
			and type(IsDualWielding) == "function"
			and IsDualWielding()

		if offhandOccupied and not isDualTwoHandLoadout then
			return { mainhandSlot, offhandSlot }, "all"
		end

		if isDualTwoHandLoadout then
			return { mainhandSlot, offhandSlot }, "any"
		end

		return { mainhandSlot }, "any"
	end

	if equipLoc == "INVTYPE_WEAPON" then
		local comparisonSlots = { mainhandSlot }
		local mainhandEquipLoc = getEquippedItemEquipLoc(runtimeContext, mainhandSlot)
		local canCompareOffhand = type(CanDualWield) == "function" and CanDualWield() and not isTwoHandWeaponEquipLoc(mainhandEquipLoc)
		if canCompareOffhand then
			local offhandEquipLoc = getEquippedItemEquipLoc(runtimeContext, offhandSlot)
			local offhandEmpty = not offhandEquipLoc or offhandEquipLoc == ""
			local offhandHasWeapon = isOneHandWeaponEquipLoc(offhandEquipLoc)
			if offhandEmpty or offhandHasWeapon then
				comparisonSlots[#comparisonSlots + 1] = offhandSlot
			end
		end
		return comparisonSlots, "any"
	end

	if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_HOLDABLE" then
		local mainhandEquipLoc = getEquippedItemEquipLoc(runtimeContext, mainhandSlot)
		if isTwoHandWeaponEquipLoc(mainhandEquipLoc) then
			return nil, nil
		end
	end

	return EQUIP_LOCATION_COMPARISON_SLOTS[equipLoc], "any"
end

local function getRuleUpgradeTrackKey(itemRef, runtimeContext)
	if not itemRef or not runtimeContext then
		return nil
	end

	local cacheKey = itemRef
	if runtimeContext.upgradeTrackCache[cacheKey] ~= nil then
		return runtimeContext.upgradeTrackCache[cacheKey] or nil
	end

	local upgradeInfo = C_Item and C_Item.GetItemUpgradeInfo and C_Item.GetItemUpgradeInfo(itemRef)
	local trackKey = addon.NormalizeUpgradeTrackKey and addon.NormalizeUpgradeTrackKey(upgradeInfo and upgradeInfo.trackStringID, upgradeInfo and upgradeInfo.trackString) or nil
	runtimeContext.upgradeTrackCache[cacheKey] = trackKey or false
	return trackKey
end

local function getRecommendationFlags(itemRef, equipLoc, classID, subClassID, runtimeContext)
	if not itemRef or not runtimeContext then
		return false, false
	end

	local cacheKey = itemRef
	local cachedFlags = runtimeContext.recommendationCache[cacheKey]
	if cachedFlags then
		return cachedFlags.recommendedForClass, cachedFlags.recommendedForSpec
	end

	if C_Item and C_Item.IsEquippableItem and not C_Item.IsEquippableItem(itemRef) then
		runtimeContext.recommendationCache[cacheKey] = {
			recommendedForClass = false,
			recommendedForSpec = false,
		}
		return false, false
	end

	if not equipLoc or classID == nil or subClassID == nil then
		local _, _, _, instantEquipLoc, _, instantClassID, instantSubClassID = GetItemInfoInstant(itemRef)
		equipLoc = equipLoc or instantEquipLoc
		classID = classID or instantClassID
		subClassID = subClassID or instantSubClassID
	end

	local recommendedForClass = false
	local recommendedForSpec = false
	if equipLoc == "INVTYPE_CLOAK" then
		recommendedForClass = true
		recommendedForSpec = true
	elseif equipLoc ~= "INVTYPE_TABARD" then
		local classFilters = addon.itemBagFilterTypes and addon.itemBagFilterTypes[runtimeContext.playerClassToken or (addon.variables and addon.variables.unitClass)]
		local specIndex = runtimeContext.playerSpecIndex or (addon.variables and addon.variables.unitSpec)
		local numericClassID = tonumber(classID)
		local numericSubClassID = tonumber(subClassID)
		local specFilters = classFilters and classFilters[specIndex]
		local specClassEntry = specFilters and numericClassID and specFilters[numericClassID]
		local specValue = specClassEntry and numericSubClassID and specClassEntry[numericSubClassID]
		recommendedForSpec = specValue ~= nil and specValue ~= false
		for _, specFilters in pairs(classFilters or {}) do
			local classEntry = numericClassID and specFilters[numericClassID]
			local value = classEntry and numericSubClassID and classEntry[numericSubClassID]
			if value ~= nil and value ~= false then
				recommendedForClass = true
				break
			end
		end
	end

	recommendedForClass = not not recommendedForClass
	recommendedForSpec = not not recommendedForSpec

	runtimeContext.recommendationCache[cacheKey] = {
		recommendedForClass = recommendedForClass,
		recommendedForSpec = recommendedForSpec,
	}

	return recommendedForClass, recommendedForSpec
end

local function isRuleUpgradeItem(equipLoc, itemLevel, recommendedForSpec, runtimeContext, classID, subClassID)
	if not recommendedForSpec or not equipLoc then
		return false
	end

	itemLevel = tonumber(itemLevel)
	if not itemLevel or itemLevel <= 0 then
		return false
	end

	local itemClass = Enum and Enum.ItemClass or {}
	if tonumber(classID) == (itemClass.Armor or 4)
		and equipLoc ~= "INVTYPE_CLOAK"
		and equipLoc ~= "INVTYPE_NECK"
		and equipLoc ~= "INVTYPE_FINGER"
		and equipLoc ~= "INVTYPE_TRINKET"
		and equipLoc ~= "INVTYPE_SHIELD"
	then
		local playerClassID = runtimeContext and runtimeContext.playerClassID
		local expectedArmorSubclass = nil
		if playerClassID == 1 or playerClassID == 2 or playerClassID == 6 then
			expectedArmorSubclass = 4
		elseif playerClassID == 3 or playerClassID == 7 or playerClassID == 13 then
			expectedArmorSubclass = 3
		elseif playerClassID == 4 or playerClassID == 10 or playerClassID == 11 or playerClassID == 12 then
			expectedArmorSubclass = 2
		elseif playerClassID == 5 or playerClassID == 8 or playerClassID == 9 then
			expectedArmorSubclass = 1
		end
		if expectedArmorSubclass and tonumber(subClassID) ~= expectedArmorSubclass then
			return false
		end
	end

	local comparisonSlots, comparisonMode = getUpgradeComparisonSlots(equipLoc, runtimeContext)
	if not comparisonSlots or #comparisonSlots == 0 then
		return false
	end

	if comparisonMode == "all" then
		local hasComparedSlot = false
		for _, inventorySlot in ipairs(comparisonSlots) do
			local equippedLevel = getEquippedItemLevel(runtimeContext, inventorySlot)
			if equippedLevel and equippedLevel > 0 then
				hasComparedSlot = true
				if itemLevel <= equippedLevel then
					return false
				end
			end
		end
		return hasComparedSlot
	end

	local baselineLevel
	for _, inventorySlot in ipairs(comparisonSlots) do
		local equippedLevel = getEquippedItemLevel(runtimeContext, inventorySlot)
		if baselineLevel == nil or equippedLevel < baselineLevel then
			baselineLevel = equippedLevel
		end
	end

	return baselineLevel ~= nil and itemLevel > baselineLevel
end

local function getDefaultCategoryForItem(info, questInfo, equipLoc, classID)
	if questInfo and (questInfo.isQuestItem or questInfo.questID) then
		return "quest"
	end

	local itemRef = info and (info.hyperlink or info.itemID)
	if not itemRef then
		return "misc"
	end

	equipLoc = equipLoc or select(4, GetItemInfoInstant(itemRef))
	classID = classID or select(6, GetItemInfoInstant(itemRef))

	if C_Item and C_Item.IsCosmeticItem then
		local ok, isCosmetic = pcall(C_Item.IsCosmeticItem, itemRef)
		if ok and isCosmetic then
			return "equipment"
		end
	end

	if equipLoc and equipLoc ~= "" and not IGNORED_ITEM_LEVEL_EQUIP_LOCS[equipLoc] then
		return "equipment"
	end

	local itemClass = Enum and Enum.ItemClass or {}
	if classID == itemClass.Weapon or classID == itemClass.Armor then
		return "equipment"
	elseif classID == itemClass.Consumable then
		return "consumables"
	elseif classID == itemClass.Tradegoods then
		return "tradegoods"
	elseif classID == itemClass.Recipe then
		return "recipes"
	end

	return "misc"
end

local function shouldCombineDuplicateItem(itemRef, settings)
	if not itemRef or not settings or not settings.combineUnstackableItems then
		return false
	end

	return true
end

local function getCollapsedItemCount(info)
	local stackCount = info and tonumber(info.stackCount) or nil
	return (stackCount and stackCount > 0) and stackCount or 1
end

local function getCollapsedItemRef(info, ruleItemInfo)
	if not info then
		return nil
	end

	local itemRef = info.hyperlink or info.itemID
	if not itemRef then
		return nil
	end

	local collapseRef = itemRef
	local itemID = tonumber(info.itemID)
	local stackCount = tonumber(info.stackCount) or 0

	if itemID then
		if stackCount > 1 then
			collapseRef = itemID
		else
			local itemInfo = ruleItemInfo or getCachedRuleItemInfo(itemRef)
			local maxStackCount = itemInfo and tonumber(itemInfo.itemStackCount) or nil
			if maxStackCount and maxStackCount > 1 then
				collapseRef = itemID
			end
		end
	end

	return collapseRef
end

local function getCollapsedItemKey(sectionID, info, ruleItemInfo)
	local collapseRef = getCollapsedItemRef(info, ruleItemInfo)
	if collapseRef == nil then
		return nil
	end

	return string.format("%s:%s", tostring(sectionID), tostring(collapseRef))
end

local function buildSectionDefinitions()
	local orderedDefinitions = {}
	local definitionMap = {}

	local newItemsDefinition = {
		id = NEW_ITEMS_DEFINITION.id,
		label = L[NEW_ITEMS_DEFINITION.labelKey] or NEW_ITEMS_DEFINITION.labelKey,
		color = NEW_ITEMS_DEFINITION.color,
		collapsible = NEW_ITEMS_DEFINITION.collapsible ~= false,
		forceHeader = NEW_ITEMS_DEFINITION.forceHeader == true,
	}
	orderedDefinitions[#orderedDefinitions + 1] = newItemsDefinition
	definitionMap[newItemsDefinition.id] = newItemsDefinition

	for _, definition in ipairs(addon.GetCategorySectionDefinitions and addon.GetCategorySectionDefinitions() or {}) do
		local resolvedDefinition = {
			id = definition.id,
			label = definition.label or (definition.labelKey and (L[definition.labelKey] or definition.labelKey)) or definition.id,
			color = definition.color or { 1, 1, 1 },
			sortMode = definition.sortMode,
			isCustom = definition.isCustom,
			groupID = definition.groupID,
			groupLabel = definition.groupLabel,
			groupColor = definition.groupColor,
			groupCollapseID = definition.groupCollapseID,
			groupSpacerBefore = definition.groupSpacerBefore == true,
			groupCombineSubcategories = definition.groupCombineSubcategories == true,
			desaturateItems = definition.desaturateItems == true,
			collapsible = definition.collapsible ~= false,
			forceHeader = definition.forceHeader == true,
		}
		orderedDefinitions[#orderedDefinitions + 1] = resolvedDefinition
		definitionMap[resolvedDefinition.id] = resolvedDefinition
	end

	local freeSlotsDefinition = {
		id = FREE_SLOTS_DEFINITION.id,
		label = L[FREE_SLOTS_DEFINITION.labelKey] or FREE_SLOTS_DEFINITION.labelKey,
		color = FREE_SLOTS_DEFINITION.color,
	}
	orderedDefinitions[#orderedDefinitions + 1] = freeSlotsDefinition
	definitionMap[freeSlotsDefinition.id] = freeSlotsDefinition

	return orderedDefinitions, definitionMap
end

local function isNewItemAtSlot(bagID, slotID)
	return C_NewItems and C_NewItems.IsNewItem and C_NewItems.IsNewItem(bagID, slotID) or false
end

state.bumpBankPerfCounter = state.bumpBankPerfCounter or function(name)
	local perf = state.getPerfBucket and state.getPerfBucket() or nil
	if not perf then
		return
	end
	perf[name] = (perf[name] or 0) + 1
end

state.getOpenSessionNewItemIdentity = state.getOpenSessionNewItemIdentity or function(bagID, slotID, info)
	if not (info and info.iconFileID) then
		return false
	end

	if ItemLocation and C_Item and C_Item.DoesItemExist and C_Item.GetItemGUID then
		local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
		if itemLocation and C_Item.DoesItemExist(itemLocation) then
			local itemGUID = C_Item.GetItemGUID(itemLocation)
			if itemGUID then
				return itemGUID
			end
		end
	end

	return info.hyperlink or info.itemID or false
end

isOpenSessionNewItem = function(bagID, slotID, info)
	state.bumpBankPerfCounter("openSessionNewItemChecks")
	local bucket = state.openSessionNewItems[bagID]
	local storedIdentity = bucket and bucket[slotID] or nil

	if not (info and info.iconFileID) then
		if bucket then
			bucket[slotID] = nil
			state.bumpBankPerfCounter("openSessionNewItemClearedEmpty")
		end
		return false
	end

	local liveNewItem = isNewItemAtSlot(bagID, slotID)
	if not liveNewItem and storedIdentity == nil then
		state.bumpBankPerfCounter("openSessionNewItemFastFalse")
		return false
	end

	state.bumpBankPerfCounter("openSessionNewItemIdentityReads")
	local identity = state.getOpenSessionNewItemIdentity(bagID, slotID, info)
	if not identity then
		if bucket then
			bucket[slotID] = nil
		end
		return false
	end

	if storedIdentity ~= nil then
		if storedIdentity == identity then
			state.bumpBankPerfCounter("openSessionNewItemSessionHit")
			return true
		end
		bucket[slotID] = nil
		state.bumpBankPerfCounter("openSessionNewItemIdentityMismatch")
	end

	if liveNewItem then
		if not bucket then
			bucket = {}
			state.openSessionNewItems[bagID] = bucket
		end
		bucket[slotID] = identity
		state.bumpBankPerfCounter("openSessionNewItemLiveHit")
		return true
	end

	return false
end

local function resetOpenSessionNewItems()
	if wipe then
		wipe(state.openSessionNewItems)
	else
		state.openSessionNewItems = {}
	end
end

local function sortLayoutSections(layoutData)
	if not layoutData or not layoutData.sectionDefinitions then
		return
	end

	local builtinSectionSortModes = {
		equipment = "itemLevel",
		consumables = "count",
		tradegoods = "count",
		recipes = "quality",
		quest = "quality",
		misc = "quality",
	}
	state.sortDataPass = (state.sortDataPass or 0) + 1
	local sortDataPass = state.sortDataPass

	local function getResolvedSectionSortMode(sectionDefinition)
		if not sectionDefinition then
			return nil
		end

		if sectionDefinition.sortMode and sectionDefinition.sortMode ~= "default" then
			return sectionDefinition.sortMode
		end

		if not sectionDefinition.isCustom then
			return builtinSectionSortModes[sectionDefinition.id]
		end

		return nil
	end

	local function prepareMappingSortData(mapping, sortMode)
		if not mapping then
			return
		end

		if mapping._bagsSortDataPass == sortDataPass then
			return
		end

		local info = mapping.itemInfo or C_Container.GetContainerItemInfo(mapping.bagID, mapping.slotID)
		local itemRef = info and (info.hyperlink or info.itemID)
		local ruleItemInfo = itemRef and getCachedRuleItemInfo(itemRef) or nil
		local itemName = (ruleItemInfo and ruleItemInfo.itemName) or (itemRef and GetItemInfo(itemRef)) or ""
		local quality = tonumber(info and info.quality) or tonumber(ruleItemInfo and ruleItemInfo.itemQuality) or -1
		local count = tonumber(mapping.itemCount) or tonumber(info and info.stackCount) or tonumber(mapping.freeSlotCount) or 0
		local sellPrice = tonumber(ruleItemInfo and ruleItemInfo.sellPrice) or 0
		local itemLink = info and info.hyperlink
		local itemLevel = 0
		local keystoneLevel = 0

		if sortMode == "itemLevel" then
			local itemLocation = ItemLocation:CreateFromBagAndSlot(mapping.bagID, mapping.slotID)
			if itemLocation and C_Item.DoesItemExist(itemLocation) and C_Item.GetCurrentItemLevel then
				local currentItemLevel = C_Item.GetCurrentItemLevel(itemLocation)
				itemLevel = tonumber(currentItemLevel) or 0
			end
			if itemLevel <= 0 and itemRef and C_Item.GetDetailedItemLevelInfo then
				local detailedItemLevel = C_Item.GetDetailedItemLevelInfo(itemRef)
				itemLevel = tonumber(detailedItemLevel) or 0
			end
		elseif sortMode == "keystoneLevel" then
			keystoneLevel = tonumber(getKeystoneLevelFromItemLink(itemLink)) or 0
		end

		mapping._bagsSortDataPass = sortDataPass
		mapping._bagsSortBagID = tonumber(mapping.bagID) or 0
		mapping._bagsSortSlotID = tonumber(mapping.slotID) or 0
		mapping._bagsSortName = string.lower(tostring(itemName or ""))
		mapping._bagsSortQuality = quality
		mapping._bagsSortCount = count
		mapping._bagsSortTotalSellPrice = sellPrice * math.max(1, count)
		mapping._bagsSortExpansionID = tonumber(ruleItemInfo and ruleItemInfo.expansionID) or -1
		mapping._bagsSortItemLevel = itemLevel
		mapping._bagsSortKeystoneLevel = keystoneLevel
	end

	local function compareSectionMappingIndices(leftIndex, rightIndex, sortMode)
		local leftMapping = state.slotMappings[leftIndex]
		local rightMapping = state.slotMappings[rightIndex]
		if not leftMapping or not rightMapping then
			return (leftIndex or 0) < (rightIndex or 0)
		end

		prepareMappingSortData(leftMapping, sortMode)
		prepareMappingSortData(rightMapping, sortMode)

		if sortMode == "itemLevel" and leftMapping._bagsSortItemLevel ~= rightMapping._bagsSortItemLevel then
			return leftMapping._bagsSortItemLevel > rightMapping._bagsSortItemLevel
		end
		if sortMode == "quality" and leftMapping._bagsSortQuality ~= rightMapping._bagsSortQuality then
			return leftMapping._bagsSortQuality > rightMapping._bagsSortQuality
		end
		if sortMode == "name" and leftMapping._bagsSortName ~= rightMapping._bagsSortName then
			return leftMapping._bagsSortName < rightMapping._bagsSortName
		end
		if sortMode == "count" and leftMapping._bagsSortCount ~= rightMapping._bagsSortCount then
			return leftMapping._bagsSortCount > rightMapping._bagsSortCount
		end
		if sortMode == "sellPrice" and leftMapping._bagsSortTotalSellPrice ~= rightMapping._bagsSortTotalSellPrice then
			return leftMapping._bagsSortTotalSellPrice > rightMapping._bagsSortTotalSellPrice
		end
		if sortMode == "expansion" and leftMapping._bagsSortExpansionID ~= rightMapping._bagsSortExpansionID then
			return leftMapping._bagsSortExpansionID > rightMapping._bagsSortExpansionID
		end
		if sortMode == "keystoneLevel" and leftMapping._bagsSortKeystoneLevel ~= rightMapping._bagsSortKeystoneLevel then
			return leftMapping._bagsSortKeystoneLevel > rightMapping._bagsSortKeystoneLevel
		end

		if leftMapping._bagsSortQuality ~= rightMapping._bagsSortQuality then
			return leftMapping._bagsSortQuality > rightMapping._bagsSortQuality
		end
		if leftMapping._bagsSortName ~= rightMapping._bagsSortName then
			return leftMapping._bagsSortName < rightMapping._bagsSortName
		end
		if leftMapping._bagsSortBagID ~= rightMapping._bagsSortBagID then
			return leftMapping._bagsSortBagID < rightMapping._bagsSortBagID
		end
		return leftMapping._bagsSortSlotID < rightMapping._bagsSortSlotID
	end

	for _, definition in ipairs(layoutData.sectionDefinitions) do
		local section = layoutData.sectionMap[definition.id]
		local sortMode = getResolvedSectionSortMode(definition)
		if section and sortMode and #section.slotIndices > 1 then
			table.sort(section.slotIndices, function(leftIndex, rightIndex)
				return compareSectionMappingIndices(leftIndex, rightIndex, sortMode)
			end)
		end
	end
end

local function ensureSection(layoutData, sectionID)
	local section = layoutData.sectionMap[sectionID]
	if section then
		return section
	end

	local definition = layoutData.sectionDefinitionsByID[sectionID] or {}
	section = {
		id = sectionID,
		label = definition.label,
		color = definition.color or { 1, 1, 1 },
		isCustom = definition.isCustom,
		groupID = definition.groupID,
		groupLabel = definition.groupLabel,
		groupColor = definition.groupColor,
		groupCollapseID = definition.groupCollapseID,
		groupSpacerBefore = definition.groupSpacerBefore == true,
		groupCombineSubcategories = definition.groupCombineSubcategories == true,
		desaturateItems = definition.desaturateItems == true,
		collapsible = definition.collapsible ~= false,
		forceHeader = definition.forceHeader == true,
		slotIndices = {},
	}
	layoutData.sectionMap[sectionID] = section
	return section
end

local function resolveCategoryForItem(bagID, slotID, info, questInfo, settings, ruleRuntimeContext, hasCustomCategories)
	local cachedSectionID, cachedCollapseRef = getCachedResolvedCategoryData(
		bagID,
		slotID,
		info,
		questInfo,
		settings,
		ruleRuntimeContext,
		hasCustomCategories
	)
	if cachedSectionID then
		return cachedSectionID, cachedCollapseRef
	end

	local showCategories = not not (settings and settings.showCategories)
	local combineDuplicates = not not (settings and settings.combineUnstackableItems)
	local itemRef = info and (info.hyperlink or info.itemID)
	local sectionID = "misc"
	local collapseRef = nil
	local stable = true
	local ruleItemInfo

	if showCategories then
		local equipLoc, _, classID, subClassID = nil, nil, nil, nil
		if itemRef then
			_, _, _, equipLoc, _, classID, subClassID = GetItemInfoInstant(itemRef)
		end
		local defaultCategory = getDefaultCategoryForItem(info, questInfo, equipLoc, classID)
		sectionID = addon.NormalizeCategorySectionID and addon.NormalizeCategorySectionID(defaultCategory) or defaultCategory

		if hasCustomCategories and addon.GetMatchingCustomCategoryID then
		local usage = ruleRuntimeContext and ruleRuntimeContext.usage or {}
			ruleItemInfo = ruleRuntimeContext and ruleRuntimeContext.hasUsage and getCachedRuleItemInfo(itemRef) or nil
			if ruleRuntimeContext and ruleRuntimeContext.hasUsage and itemRef and not (ruleItemInfo and ruleItemInfo.loaded) then
				stable = false
			end

			local resolvedItemLevel
			local itemLocation
			if usage.itemLevel or usage.equippedAverageItemLevel or usage.isUpgrade or usage.canAuctionHouseSell then
				itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
			end
			if usage.itemLevel or usage.equippedAverageItemLevel or usage.isUpgrade then
				resolvedItemLevel = ruleItemInfo and ruleItemInfo.itemLevel or nil

				if itemLocation and C_Item.DoesItemExist(itemLocation) and C_Item.GetCurrentItemLevel then
					resolvedItemLevel = C_Item.GetCurrentItemLevel(itemLocation) or resolvedItemLevel
				end

				if (not resolvedItemLevel or resolvedItemLevel <= 0) and itemRef and C_Item.GetDetailedItemLevelInfo then
					resolvedItemLevel = C_Item.GetDetailedItemLevelInfo(itemRef) or resolvedItemLevel
				end

				resolvedItemLevel = tonumber(resolvedItemLevel) or nil
				if not resolvedItemLevel or resolvedItemLevel <= 0 then
					stable = false
				end
			end

			classID = (ruleItemInfo and ruleItemInfo.classID) or classID
			subClassID = (ruleItemInfo and ruleItemInfo.subclassID) or subClassID
			equipLoc = (ruleItemInfo and ruleItemInfo.itemEquipLoc) or equipLoc
			local recommendedForClass
			local recommendedForSpec
			if usage.recommendedForClass or usage.recommendedForSpec or usage.isUpgrade then
				recommendedForClass, recommendedForSpec = getRecommendationFlags(itemRef, equipLoc, classID, subClassID, ruleRuntimeContext)
			end

			local upgradeTrackKey
			if usage.upgradeTrackKey then
				upgradeTrackKey = getRuleUpgradeTrackKey(itemRef, ruleRuntimeContext)
			end

			local canAuctionHouseSell
			if usage.canAuctionHouseSell then
				stable = false
				canAuctionHouseSell = itemLocation and itemLocation:IsValid() and C_AuctionHouse and C_AuctionHouse.IsSellItemValid and C_AuctionHouse.IsSellItemValid(itemLocation, false) or false
			end

			local isEquipmentSet
			if usage.isEquipmentSet then
				isEquipmentSet = C_Container
					and C_Container.GetContainerItemEquipmentSetInfo
					and C_Container.GetContainerItemEquipmentSetInfo(bagID, slotID)
					or false
			end

			local tooltipFlags
			local needsTransmogTooltip = usage.isTransmogSet
				and tonumber(classID) == CONSUMABLE_CLASS_ID
				and tonumber(subClassID) == CONSUMABLE_OTHER_SUBCLASS_ID
			if usage.isToy or usage.isPvpItem or needsTransmogTooltip then
				tooltipFlags = getTooltipDerivedItemFlags(bagID, slotID, info, ruleRuntimeContext)
			end

			local isTransmogSet
			if needsTransmogTooltip then
				isTransmogSet = tooltipFlags and tooltipFlags.isTransmogSet or false
			end

			local isToy
			if usage.isToy then
				isToy = tooltipFlags and tooltipFlags.isToy or false
			end

			local isPvpItem
			if usage.isPvpItem then
				isPvpItem = tooltipFlags and tooltipFlags.isPvpItem or false
			end

			local resolvedBindType = ruleItemInfo and ruleItemInfo.bindType or nil
			if usage.bindType then
				local tooltipBindType = getTooltipResolvedBindType(bagID, slotID, info, ruleRuntimeContext)
				if tooltipBindType ~= nil then
					resolvedBindType = tooltipBindType
				end
			end

			local itemContext = ruleRuntimeContext and ruleRuntimeContext.itemContext or {}
			if next(itemContext) ~= nil and wipe then
				wipe(itemContext)
			end
			itemContext.bagID = bagID
			itemContext.slotID = slotID
			itemContext.itemID = info and info.itemID
			itemContext.itemName = ruleItemInfo and ruleItemInfo.itemName or nil
			itemContext.itemLink = (ruleItemInfo and ruleItemInfo.itemLink) or (info and info.hyperlink)
			itemContext.itemDescription = ruleItemInfo and ruleItemInfo.itemDescription or nil
			itemContext.quality = (ruleItemInfo and ruleItemInfo.itemQuality) or (info and info.quality)
			itemContext.itemLevel = resolvedItemLevel
			itemContext.equippedAverageItemLevel = usage.equippedAverageItemLevel
				and equipLoc
				and not IGNORED_ITEM_LEVEL_EQUIP_LOCS[equipLoc]
				and (
					tonumber(classID) == (Enum and Enum.ItemClass and Enum.ItemClass.Armor or 4)
					or tonumber(classID) == (Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2)
				)
				and Bags.functions.GetRuleEquippedAverageItemLevel(ruleRuntimeContext)
				or nil
			itemContext.itemMinLevel = ruleItemInfo and ruleItemInfo.itemMinLevel or nil
			itemContext.itemType = ruleItemInfo and ruleItemInfo.itemType or nil
			itemContext.itemSubType = ruleItemInfo and ruleItemInfo.itemSubType or nil
			itemContext.itemStackCount = (ruleItemInfo and ruleItemInfo.itemStackCount) or (info and info.stackCount) or 0
			itemContext.itemTexture = (ruleItemInfo and ruleItemInfo.itemTexture) or (info and info.iconFileID)
			itemContext.sellPrice = (ruleItemInfo and ruleItemInfo.sellPrice) or 0
			itemContext.classID = classID
			itemContext.subClassID = subClassID
			itemContext.subClassKey = classID and subClassID and string.format("%d:%d", classID, subClassID) or nil
			itemContext.professionGroupKey = addon.GetProfessionGroupKeyForItem
				and addon.GetProfessionGroupKeyForItem(classID, subClassID, info and info.itemID)
				or nil
			itemContext.bindType = resolvedBindType
			itemContext.expansionID = ruleItemInfo and ruleItemInfo.expansionID or nil
			itemContext.setID = ruleItemInfo and ruleItemInfo.setID or nil
			itemContext.isCraftingReagent = not not (ruleItemInfo and ruleItemInfo.isCraftingReagent)
			itemContext.isBound = info and info.isBound
			itemContext.recommendedForSpec = not not recommendedForSpec
			itemContext.recommendedForClass = not not recommendedForClass
			itemContext.isUpgrade = usage.isUpgrade and isRuleUpgradeItem(equipLoc, resolvedItemLevel, recommendedForSpec, ruleRuntimeContext, classID, subClassID) or false
			itemContext.upgradeTrackKey = upgradeTrackKey
			itemContext.canVendor = ((ruleItemInfo and ruleItemInfo.sellPrice) or 0) > 0
			itemContext.canAuctionHouseSell = not not canAuctionHouseSell
			itemContext.isEquipmentSet = not not isEquipmentSet
			itemContext.isTransmogSet = not not isTransmogSet
			itemContext.isToy = not not isToy
			itemContext.isPvpItem = not not isPvpItem
			itemContext.isTeleportItem = addon.MythicPlus
				and addon.MythicPlus.functions
				and addon.MythicPlus.functions.IsTeleportItem
				and addon.MythicPlus.functions.IsTeleportItem(info and info.itemID)
				or false
			itemContext.isHearthstone = usage.isHearthstone and isRuleHearthstoneItem(info and info.itemID) or false
			itemContext.isKeystone = usage.isKeystone and isKeystoneItem(info and info.itemID) or false
			itemContext.equipLoc = equipLoc
			itemContext.defaultCategory = defaultCategory
			itemContext.isQuestItem = questInfo and questInfo.isQuestItem or false
			itemContext.questID = questInfo and questInfo.questID or nil

			local customCategoryID = addon.GetMatchingCustomCategoryID and addon.GetMatchingCustomCategoryID(itemContext)
			if customCategoryID then
				sectionID = addon.NormalizeCategorySectionID and addon.NormalizeCategorySectionID(customCategoryID) or customCategoryID
			end
		end
	end

	if isOpenSessionNewItem(bagID, slotID, info) then
		sectionID = NEW_ITEMS_SECTION_ID
	end

	if combineDuplicates then
		collapseRef = getCollapsedItemRef(info, ruleItemInfo)
	end

	updateResolvedCategoryCache(
		bagID,
		slotID,
		info,
		questInfo,
		settings,
		ruleRuntimeContext,
		hasCustomCategories,
		sectionID,
		collapseRef,
		stable
	)
	return sectionID, collapseRef
end

local function addSlotMapping(layoutData, sectionID, bagID, slotID, extraData)
	local section = ensureSection(layoutData, sectionID)
	local index = layoutData.requiredButtonCount + 1
	local mapping = state.slotMappings[index] or {}
	mapping.bagID = bagID
	mapping.slotID = slotID
	mapping.freeSlotGroup = extraData and extraData.freeSlotGroup or nil
	mapping.freeSlotCount = extraData and extraData.freeSlotCount or nil
	mapping.itemCount = extraData and extraData.itemCount or nil
	mapping.itemInfo = extraData and extraData.itemInfo or nil
	mapping.questInfo = extraData and extraData.questInfo or nil
	mapping.desaturateItem = section.desaturateItems == true and mapping.itemInfo ~= nil or nil
	state.slotMappings[index] = mapping

	layoutData.requiredButtonCount = index
	section.slotIndices[#section.slotIndices + 1] = index
	return index, mapping
end

local function isOneBagMode(settings)
	if addon.GetOneBagMode then
		return addon.GetOneBagMode()
	end
	return settings and settings.oneBagMode == true or false
end

local function shouldMoveOneBagFreeSlotsToEnd(settings)
	if not isOneBagMode(settings) then
		return false
	end
	if addon.GetOneBagFreeSlotsAtEnd then
		return addon.GetOneBagFreeSlotsAtEnd()
	end
	return settings and settings.oneBagFreeSlotsAtEnd == true or false
end

local function buildLayoutData(context)
	local settings = getSettings()
	local oneBagMode = isOneBagMode(settings)
	local oneBagFreeSlotsAtEnd = shouldMoveOneBagFreeSlotsToEnd(settings)
	local hasCustomCategories = not oneBagMode and settings.showCategories and addon.HasCustomCategories and addon.HasCustomCategories() or false
	local ruleUsage = hasCustomCategories and addon.GetCategoryRuleContextUsage and addon.GetCategoryRuleContextUsage() or nil
	local ruleRuntimeContext = hasCustomCategories and createRuleRuntimeContext(ruleUsage) or nil
	local layoutData = {
		requiredButtonCount = 0,
		sectionMap = {},
		sections = {},
		sectionDefinitions = {},
		sectionDefinitionsByID = {},
		totalSlotCount = 0,
		collapsedItems = {},
		freeSlotCount = 0,
		freeSlotReference = {},
		oneBagFreeSlots = {},
	}
	if oneBagMode then
		layoutData.sectionDefinitions = {}
		layoutData.sectionDefinitionsByID = {}
	else
		layoutData.sectionDefinitions, layoutData.sectionDefinitionsByID = buildSectionDefinitions()
	end

	for _, bagID in ipairs(context and context.bagIDs or {}) do
		local slotCount = C_Container.GetContainerNumSlots(bagID) or 0
		layoutData.totalSlotCount = layoutData.totalSlotCount + slotCount

		for slotID = 1, slotCount do
			local info = C_Container.GetContainerItemInfo(bagID, slotID)
			local hasItem = info and info.iconFileID

			if hasItem then
				local questInfo
				local sectionID = "misc"
				local collapseRef = nil
				if not oneBagMode and (settings.showCategories or settings.combineUnstackableItems or isOpenSessionNewItem(bagID, slotID, info)) then
					questInfo = settings.showCategories and C_Container.GetContainerItemQuestInfo(bagID, slotID) or nil
					sectionID, collapseRef = resolveCategoryForItem(
						bagID,
						slotID,
						info,
						questInfo,
						settings,
						ruleRuntimeContext,
						hasCustomCategories
					)
				end
				local hideItem = not oneBagMode and addon.IsCategorySectionHidden and addon.IsCategorySectionHidden(sectionID)
				local itemRef = info and (info.hyperlink or info.itemID)
				if hideItem then
					clearSlotCategoryCacheEntry(bagID, slotID)
				elseif not oneBagMode and shouldCombineDuplicateItem(itemRef, settings) then
					local collapsedSection = layoutData.collapsedItems[sectionID]
					if not collapsedSection then
						collapsedSection = {}
						layoutData.collapsedItems[sectionID] = collapsedSection
					end
					local collapsedMapping = collapseRef ~= nil and collapsedSection[collapseRef] or nil
					if collapsedMapping then
						collapsedMapping.itemCount = (collapsedMapping.itemCount or 1) + getCollapsedItemCount(info)
					else
						local _, mapping = addSlotMapping(
							layoutData,
							sectionID,
							bagID,
							slotID,
							{
								itemCount = getCollapsedItemCount(info),
								itemInfo = info,
								questInfo = questInfo,
							}
						)
						if collapseRef ~= nil then
							collapsedSection[collapseRef] = mapping
						end
					end
				else
					addSlotMapping(layoutData, sectionID, bagID, slotID, {
						itemInfo = info,
						questInfo = questInfo,
					})
				end
			else
				clearSlotCategoryCacheEntry(bagID, slotID)
				layoutData.freeSlotCount = layoutData.freeSlotCount + 1
				if not layoutData.freeSlotReference.bagID then
					layoutData.freeSlotReference.bagID = bagID
					layoutData.freeSlotReference.slotID = slotID
				end

				if oneBagMode then
					if settings.showFreeSlots ~= false and oneBagFreeSlotsAtEnd then
						layoutData.oneBagFreeSlots[#layoutData.oneBagFreeSlots + 1] = {
							bagID = bagID,
							slotID = slotID,
							freeSlotGroup = "normal",
						}
					elseif settings.showFreeSlots ~= false then
						addSlotMapping(layoutData, "misc", bagID, slotID, {
							freeSlotGroup = "normal",
						})
					end
				elseif settings.showFreeSlots ~= false and not settings.combineFreeSlots then
					local sectionID = settings.showCategories and FREE_SLOTS_SECTION_ID or "misc"
					addSlotMapping(layoutData, sectionID, bagID, slotID, {
						freeSlotGroup = "normal",
					})
				end
			end
		end
	end

	if oneBagMode and oneBagFreeSlotsAtEnd and settings.showFreeSlots ~= false then
		for _, freeSlot in ipairs(layoutData.oneBagFreeSlots) do
			addSlotMapping(layoutData, "misc", freeSlot.bagID, freeSlot.slotID, {
				freeSlotGroup = freeSlot.freeSlotGroup or "normal",
			})
		end
	end

	if not oneBagMode and settings.showFreeSlots ~= false and settings.combineFreeSlots and layoutData.freeSlotCount > 0 and layoutData.freeSlotReference.bagID then
		local sectionID = settings.showCategories and FREE_SLOTS_SECTION_ID or "misc"
		addSlotMapping(
			layoutData,
			sectionID,
			layoutData.freeSlotReference.bagID,
			layoutData.freeSlotReference.slotID,
			{
				freeSlotGroup = "normal",
				freeSlotCount = layoutData.freeSlotCount,
			}
		)
	end

	if not oneBagMode then
		sortLayoutSections(layoutData)
	end

	if oneBagMode then
		local flatSection = layoutData.sectionMap.misc
		if flatSection and #flatSection.slotIndices > 0 then
			flatSection.label = nil
			flatSection.collapsible = false
			layoutData.sections[#layoutData.sections + 1] = flatSection
		end
	elseif settings.showCategories then
		for _, definition in ipairs(layoutData.sectionDefinitions) do
			local section = layoutData.sectionMap[definition.id]
			if section and #section.slotIndices > 0 then
				layoutData.sections[#layoutData.sections + 1] = section
			end
		end
	else
		local newItemsSection = layoutData.sectionMap[NEW_ITEMS_SECTION_ID]
		if newItemsSection and #newItemsSection.slotIndices > 0 then
			layoutData.sections[#layoutData.sections + 1] = newItemsSection
		end
		local flatSection = layoutData.sectionMap.misc
		if flatSection and #flatSection.slotIndices > 0 then
			layoutData.sections[#layoutData.sections + 1] = flatSection
			flatSection.label = nil
		end
	end

	for cleanupIndex = layoutData.requiredButtonCount + 1, #state.slotMappings do
		state.slotMappings[cleanupIndex] = nil
	end

	state.layoutData = layoutData
	return layoutData
end

state.addBankCategoryWithdrawSlot = state.addBankCategoryWithdrawSlot or function(slots, seen, context, bagID, slotID, mapping)
	if not context or type(bagID) ~= "number" or type(slotID) ~= "number" then
		return
	end
	if mapping and mapping.freeSlotGroup then
		return
	end

	local inContext = false
	for _, contextBagID in ipairs(context.bagIDs or {}) do
		if contextBagID == bagID then
			inContext = true
			break
		end
	end
	if not inContext then
		return
	end

	local info = (mapping and mapping.itemInfo) or (C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bagID, slotID)) or nil
	if not (info and info.iconFileID) or info.isLocked then
		return
	end

	local seenBag = seen[bagID]
	if not seenBag then
		seenBag = {}
		seen[bagID] = seenBag
	end
	if seenBag[slotID] then
		return
	end

	seenBag[slotID] = true
	slots[#slots + 1] = {
		bagID = bagID,
		slotID = slotID,
	}
end

state.collectBankCategoryWithdrawSectionIDs = state.collectBankCategoryWithdrawSectionIDs or function(sectionID)
	local sectionIDs = {}
	if not sectionID or sectionID == FREE_SLOTS_SECTION_ID then
		return sectionIDs
	end

	local layoutData = state.layoutData
	if layoutData and layoutData.sectionMap and layoutData.sectionMap[sectionID] then
		sectionIDs[sectionID] = true
		return sectionIDs
	end

	if layoutData and layoutData.sectionDefinitions then
		for _, definition in ipairs(layoutData.sectionDefinitions) do
			if definition.groupCollapseID == sectionID then
				sectionIDs[definition.id] = true
			end
		end
	end

	return sectionIDs
end

state.collectBankCategoryWithdrawSlots = state.collectBankCategoryWithdrawSlots or function(sectionID)
	local layoutData = state.layoutData
	local context = getVisibleContext()
	if not (layoutData and layoutData.sectionMap and context) then
		return nil
	end

	local withdrawSectionIDs = state.collectBankCategoryWithdrawSectionIDs(sectionID)
	if not next(withdrawSectionIDs) then
		return nil
	end

	local slots = {}
	local seen = {}
	for withdrawSectionID in pairs(withdrawSectionIDs) do
		local section = layoutData.sectionMap[withdrawSectionID]
		for _, mappingIndex in ipairs(section and section.slotIndices or {}) do
			local mapping = state.slotMappings[mappingIndex]
			if mapping then
				state.addBankCategoryWithdrawSlot(slots, seen, context, mapping.bagID, mapping.slotID, mapping)
			end
		end
	end

	for _, bagID in ipairs(context.bagIDs or {}) do
		local slotCount = C_Container.GetContainerNumSlots(bagID) or 0
		local categoryBucket = state.slotCategoryCache and state.slotCategoryCache[bagID] or nil
		for slotID = 1, slotCount do
			local entry = categoryBucket and categoryBucket[slotID] or nil
			if entry and withdrawSectionIDs[entry.sectionID] then
				state.addBankCategoryWithdrawSlot(slots, seen, context, bagID, slotID)
			elseif withdrawSectionIDs[NEW_ITEMS_SECTION_ID] and isOpenSessionNewItem(bagID, slotID, C_Container.GetContainerItemInfo(bagID, slotID)) then
				state.addBankCategoryWithdrawSlot(slots, seen, context, bagID, slotID)
			end
		end
	end

	return slots
end

state.withdrawBankSlotsToBags = state.withdrawBankSlotsToBags or function(slots)
	if type(slots) ~= "table" or #slots == 0 or not C_Container or not C_Container.UseContainerItem then
		return false
	end

	if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	end

	return state.startCategoryTransferQueue("withdraw", nil, slots, "CategoryWithdraw")
end

state.withdrawBankCategoryToBags = state.withdrawBankCategoryToBags or function(sectionID)
	local slots = state.collectBankCategoryWithdrawSlots(sectionID)
	if not slots or #slots == 0 then
		return false
	end

	return state.withdrawBankSlotsToBags(slots)
end

local function configureSectionHeader(header, options)
	if not header or not options then
		return
	end

	local isCollapsed = not not options.collapsed
	local isCollapsible = options.collapsible ~= false
	local color = options.color or { 1, 1, 1 }

	header:SetHeight(SECTION_HEADER_HEIGHT)
	header.sectionID = options.sectionID
	header.categoryLabel = options.label or ""
	header.categoryColor = color
	header._bagsTextElementID = options.textElementID or "subcategoryHeader"
	if isCollapsible then
		header.Icon.Left:SetAtlas(SECTION_TOGGLE_LEFT_ATLAS, false)
		header.Icon.Right:SetAtlas(isCollapsed and SECTION_TOGGLE_COLLAPSED_ATLAS or SECTION_TOGGLE_EXPANDED_ATLAS, false)
		header.Icon.Left:SetSize(SECTION_TOGGLE_LEFT_WIDTH, SECTION_HEADER_HEIGHT)
		header.Icon.Right:SetSize(SECTION_TOGGLE_RIGHT_WIDTH, SECTION_HEADER_HEIGHT)
		header.Icon.Left:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, 1)
		header.Icon.Right:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, 1)
		header.Icon:Show()
	else
		header.Icon:Hide()
	end
	if header.HighlightTexture then
		header.HighlightTexture:SetShown(isCollapsible)
	end
	header.Text:SetText(addon.FormatTextElement and addon.FormatTextElement(header._bagsTextElementID, options.label or "") or options.label or "")
	header.Text:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1)
	applyConfiguredFont(header.Text, nil, header._bagsTextElementID)
	layoutSectionHeaderText(header)
	applySectionHeaderSkin(header, getActiveFrameSkin())
end

local function acquireSectionHeader(index)
	local header = state.sectionHeaders[index]
	if header then
		return header
	end

	header = CreateFrame("Button", nil, state.content)
	header:SetHeight(SECTION_HEADER_HEIGHT)
	header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	header:EnableMouseWheel(true)
	header:SetScript("OnMouseWheel", function(_, delta)
		handleScrollWheel(delta)
	end)
	if installFrameDropReceiver then
		installFrameDropReceiver(header)
	end

	local highlight = header:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetPoint("TOPLEFT", header, "TOPLEFT", -2, 0)
	highlight:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 4, 0)
	highlight:SetColorTexture(1, 1, 1, 0.08)
	header.HighlightTexture = highlight

	local icon = CreateFrame("Frame", nil, header)
	icon:SetSize(SECTION_TOGGLE_WIDTH, SECTION_HEADER_HEIGHT)
	icon:SetPoint("LEFT", header, "LEFT", 0, 0)
	header.Icon = icon
	icon.Left = icon:CreateTexture(nil, "ARTWORK")
	icon.Left:SetPoint("LEFT", icon, "LEFT", 0, 0)
	icon.Right = icon:CreateTexture(nil, "ARTWORK")
	icon.Right:SetPoint("LEFT", icon.Left, "RIGHT", 0, 0)

	local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	header.Text = text

	header:SetScript("OnClick", function(self, mouseButton)
		if receiveCursorItemIntoVisibleBank() then
			return
		end

		if mouseButton == "RightButton" and not IsModifiedClick() and state.withdrawBankCategoryToBags(self.sectionID) then
			return
		end

		if self.sectionID then
			toggleSectionCollapsed(self.sectionID)
		end
	end)
	header:SetScript("OnEnter", function(self)
		if not self.categoryLabel or self.categoryLabel == "" then
			return
		end

		local color = self.categoryColor or { 1, 1, 1 }
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(self.categoryLabel, color[1] or 1, color[2] or 1, color[3] or 1)
		GameTooltip:Show()
	end)
	header:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	state.sectionHeaders[index] = header
	applyConfiguredFrameFonts()
	applySectionHeaderSkin(header, getActiveFrameSkin())
	return header
end

local function acquireGroupSpacer(index)
	local spacer = state.groupSpacers[index]
	if spacer then
		return spacer
	end

	spacer = CreateFrame("Frame", nil, state.content)
	spacer:SetHeight(1)
	spacer.Line = spacer:CreateTexture(nil, "BORDER")
	spacer.Line:SetAllPoints()
	spacer.Line:SetColorTexture(1, 1, 1, 0.08)
	state.groupSpacers[index] = spacer
	return spacer
end

local function hasMatchingButtonRenderState(
	button,
	bagID,
	slotID,
	texture,
	displayCount,
	locked,
	desaturated,
	quality,
	readable,
	itemLink,
	itemID,
	noValue,
	isBound,
	questIsQuestItem,
	questID,
	questIsActive,
	isNewItem,
	isUnusableRecipe,
	overlayVersion,
	fontSignature,
	stackCountLayoutSignature,
	freeSlotSignature
)
	return button._bagsWarbandRenderBagID == bagID
		and button._bagsWarbandRenderSlotID == slotID
		and button._bagsWarbandRenderTexture == texture
		and button._bagsWarbandRenderDisplayCount == displayCount
		and button._bagsWarbandRenderLocked == locked
		and button._bagsWarbandRenderDesaturated == desaturated
		and button._bagsWarbandRenderQuality == quality
		and button._bagsWarbandRenderReadable == readable
		and button._bagsWarbandRenderItemLink == itemLink
		and button._bagsWarbandRenderItemID == itemID
		and button._bagsWarbandRenderNoValue == noValue
		and button._bagsWarbandRenderBound == isBound
		and button._bagsWarbandRenderQuestItem == questIsQuestItem
		and button._bagsWarbandRenderQuestID == questID
		and button._bagsWarbandRenderQuestActive == questIsActive
		and button._bagsWarbandRenderNewItem == isNewItem
		and button._bagsWarbandRenderUnusableRecipe == isUnusableRecipe
		and button._bagsWarbandRenderOverlayVersion == overlayVersion
		and button._bagsWarbandRenderFontSignature == fontSignature
		and button._bagsWarbandRenderStackCountLayoutSignature == stackCountLayoutSignature
		and button._bagsWarbandRenderFreeSlotSignature == freeSlotSignature
end

local function updateButtonSearchState(button, isFiltered)
	button:SetMatchesSearch(not isFiltered)
	button._bagsWarbandRenderFiltered = isFiltered
end

local function storeButtonRenderState(
	button,
	bagID,
	slotID,
	texture,
	displayCount,
	locked,
	desaturated,
	quality,
	readable,
	itemLink,
	itemID,
	isFiltered,
	noValue,
	isBound,
	questIsQuestItem,
	questID,
	questIsActive,
	isNewItem,
	isUnusableRecipe,
	overlayVersion,
	fontSignature,
	stackCountLayoutSignature,
	freeSlotSignature
)
	button._bagsWarbandRenderBagID = bagID
	button._bagsWarbandRenderSlotID = slotID
	button._bagsWarbandRenderTexture = texture
	button._bagsWarbandRenderDisplayCount = displayCount
	button._bagsWarbandRenderLocked = locked
	button._bagsWarbandRenderDesaturated = desaturated
	button._bagsWarbandRenderQuality = quality
	button._bagsWarbandRenderReadable = readable
	button._bagsWarbandRenderItemLink = itemLink
	button._bagsWarbandRenderItemID = itemID
	button._bagsWarbandRenderFiltered = isFiltered
	button._bagsWarbandRenderNoValue = noValue
	button._bagsWarbandRenderBound = isBound
	button._bagsWarbandRenderQuestItem = questIsQuestItem
	button._bagsWarbandRenderQuestID = questID
	button._bagsWarbandRenderQuestActive = questIsActive
	button._bagsWarbandRenderNewItem = isNewItem
	button._bagsWarbandRenderUnusableRecipe = isUnusableRecipe
	button._bagsWarbandRenderOverlayVersion = overlayVersion
	button._bagsWarbandRenderFontSignature = fontSignature
	button._bagsWarbandRenderStackCountLayoutSignature = stackCountLayoutSignature
	button._bagsWarbandRenderFreeSlotSignature = freeSlotSignature
end

local function getFreeSlotRenderSignature(freeSlotGroup)
	if not freeSlotGroup then
		return ""
	end

	local displayMode = addon.GetFreeSlotDisplayMode and addon.GetFreeSlotDisplayMode() or "icons"
	if displayMode ~= "colors" then
		return tostring(freeSlotGroup) .. ":" .. tostring(displayMode)
	end

	local color = addon.GetFreeSlotColor and addon.GetFreeSlotColor(freeSlotGroup) or nil
	return string.format(
		"%s:colors:%.3f:%.3f:%.3f",
		tostring(freeSlotGroup),
		tonumber(color and color[1]) or 0,
		tonumber(color and color[2]) or 0,
		tonumber(color and color[3]) or 0
	)
end

function Bags.functions.GetWarbandItemButtonSkinSignature()
	return state.currentSkinSignature or (addon.GetSkinSignature and addon.GetSkinSignature()) or false
end

function Bags.functions.ApplyWarbandItemButtonSkinIfNeeded(button, quality, force)
	if not button or not addon.ApplyItemButtonSkin then
		return
	end

	local skinSignature = Bags.functions.GetWarbandItemButtonSkinSignature()
	if not force and button._bagsAppliedSkinSignature == skinSignature then
		return
	end

	addon.ApplyItemButtonSkin(button, quality)
	button._bagsAppliedSkinSignature = skinSignature
end

state.getStackCountLayoutSignature = state.getStackCountLayoutSignature or function()
	return addon.GetStackCountLayoutSignature and addon.GetStackCountLayoutSignature()
		or (addon.GetStackCountAnchor and addon.GetStackCountAnchor() or "BOTTOMRIGHT")
end

state.applyStackCountLayoutIfNeeded = state.applyStackCountLayoutIfNeeded or function(button, signature)
	if not (button and addon.ApplyStackCountLayout) then
		return
	end

	local count = button.Count
	if count and count._bagsStackCountLayoutSignature == signature then
		return
	end

	addon.ApplyStackCountLayout(button)
	if count then
		count._bagsStackCountLayoutSignature = signature
	end
end

state.applyCraftedQualityPreference = state.applyCraftedQualityPreference or function(button, quality, itemLink, isBound, force)
	local alwaysShow = addon.GetShowCraftedQuality and addon.GetShowCraftedQuality() or false
	local changed = button.alwaysShowProfessionsQuality ~= alwaysShow
	button.alwaysShowProfessionsQuality = alwaysShow
	if (force or changed) and SetItemButtonQuality then
		SetItemButtonQuality(button, quality, itemLink, false, isBound)
	end
end

local function updateButtonData(button, mapping, overlayRuntime, textAppearance, fontSignature, tooltipOwner, forceDynamicUpdate, stackCountLayoutSignature)
	if not button then
		return
	end

	if mapping and mapping.sectionCollapsed then
		button:Hide()
		return
	end

	local bagID = button:GetBagID()
	local slotID = button:GetID()
	local info = C_Container.GetContainerItemInfo(bagID, slotID)
	local texture = info and info.iconFileID
	local itemCount = info and info.stackCount
	local displayItemCount = mapping and mapping.itemCount
	local freeSlotCount = mapping and mapping.freeSlotCount
	local locked = info and info.isLocked
	local desaturateItem = texture and mapping and mapping.desaturateItem == true or false
	local desaturated = locked or desaturateItem
	local quality = info and info.quality
	local readable = info and (info.IsReadable or info.isReadable)
	local itemLink = info and info.hyperlink
	local itemID = info and info.itemID
	local isFiltered = info and info.isFiltered
	local noValue = info and info.hasNoValue
	local isBound = info and info.isBound
	local questInfo = C_Container.GetContainerItemQuestInfo(bagID, slotID)
	local displayCount = freeSlotCount or displayItemCount or itemCount
	local questIsQuestItem = questInfo and questInfo.isQuestItem or false
	local questID = questInfo and questInfo.questID or nil
	local questIsActive = questInfo and questInfo.isActive or false
	local isNewItem = isNewItemAtSlot(bagID, slotID)
	local tooltipFlags = texture and getTooltipDerivedItemFlags(bagID, slotID, info) or nil
	local isKnownToy = tooltipFlags and tooltipFlags.isKnownToy or false
	local hasUsageRequirement = tooltipFlags and tooltipFlags.hasUsageRequirement or false
	local isUnusableRecipe = (texture and Bags.functions.IsRecipeUnusableByPlayer and Bags.functions.IsRecipeUnusableByPlayer(itemID, itemLink) or false) or isKnownToy or hasUsageRequirement
	local freeSlotGroup = mapping and mapping.freeSlotGroup or nil
	local freeSlotSignature = getFreeSlotRenderSignature(freeSlotGroup)
	overlayRuntime = overlayRuntime or getOverlayRuntimeConfig()
	fontSignature = fontSignature or getTextAppearanceSignature(textAppearance)
	local overlayVersion = overlayRuntime and overlayRuntime.version or 0
	stackCountLayoutSignature = stackCountLayoutSignature or state.getStackCountLayoutSignature()

	if hasMatchingButtonRenderState(
		button,
		bagID,
		slotID,
		texture,
		displayCount,
		locked,
		desaturated,
		quality,
		readable,
		itemLink,
		itemID,
		noValue,
		isBound,
		questIsQuestItem,
		questID,
		questIsActive,
		isNewItem,
		isUnusableRecipe,
		overlayVersion,
		fontSignature,
		stackCountLayoutSignature,
		freeSlotSignature
	) then
		if not button:IsShown() then
			button:Show()
		end
		Bags.functions.ApplyWarbandItemButtonSkinIfNeeded(button, quality)
		state.applyStackCountLayoutIfNeeded(button, stackCountLayoutSignature)
		state.applyCraftedQualityPreference(button, quality, itemLink, isBound)
		applyConfiguredOverlayAnchors(button, overlayRuntime)
		updateEquipmentSetOverlay(button, bagID, slotID, info, overlayRuntime)
		updateBindStatusOverlay(button, bagID, slotID, info, overlayRuntime)
		if button._bagsWarbandRenderFiltered ~= isFiltered then
			updateButtonSearchState(button, isFiltered)
		end
		if forceDynamicUpdate then
			button:UpdateCooldown(texture)
			if addon.RefreshItemButtonCooldownMask then
				addon.RefreshItemButtonCooldownMask(button)
			end
			if tooltipOwner then
				button:CheckUpdateTooltip(tooltipOwner)
			end
		end
		if Bags.functions.ApplyRecipeUsabilityVisual then
			Bags.functions.ApplyRecipeUsabilityVisual(button, isUnusableRecipe)
		end
		return
	end

	if ClearItemButtonOverlay then
		ClearItemButtonOverlay(button)
	end

	button:SetHasItem(texture)
	button:SetItemButtonTexture(texture)
	state.applyCraftedQualityPreference(button, quality, itemLink, isBound, true)
	SetItemButtonCount(button, displayCount)
	SetItemButtonDesaturated(button, desaturated)
	button:UpdateExtended()
	button:UpdateQuestItem(questIsQuestItem, questID, questIsActive)
	button:UpdateNewItem(quality)
	button:UpdateJunkItem(quality, noValue)
	updateJunkCoinIcon(button, quality)
	button:UpdateItemContextMatching()
	button:UpdateCooldown(texture)
	button:SetReadable(readable)
	updateButtonSearchState(button, isFiltered)
	button._bagsFreeSlotGroup = freeSlotGroup
	button._bagsFreeSlotDisplayMode = freeSlotGroup and addon.GetFreeSlotDisplayMode and addon.GetFreeSlotDisplayMode() or nil
	button._bagsFreeSlotColor = button._bagsFreeSlotDisplayMode == "colors" and addon.GetFreeSlotColor and addon.GetFreeSlotColor(freeSlotGroup) or nil

	if tooltipOwner then
		button:CheckUpdateTooltip(tooltipOwner)
	end

	button._bagsWarbandHasPendingRenderTexture = true
	button._bagsWarbandPendingRenderTexture = texture
	Bags.functions.ApplyWarbandItemButtonSkinIfNeeded(button, quality, true)
	if Bags.functions.ApplyRecipeUsabilityVisual then
		Bags.functions.ApplyRecipeUsabilityVisual(button, isUnusableRecipe)
	end
	if addon.RefreshItemButtonCooldownMask then
		addon.RefreshItemButtonCooldownMask(button)
	end
	applyConfiguredItemButtonFonts(button, textAppearance, fontSignature)
	state.applyStackCountLayoutIfNeeded(button, stackCountLayoutSignature)
	applyConfiguredOverlayAnchors(button, overlayRuntime)
	updateItemLevelText(button, itemLink, itemID, quality, overlayRuntime)
	updateItemUpgradeText(button, itemLink, itemID, overlayRuntime)
	updateEquipmentSetOverlay(button, bagID, slotID, info, overlayRuntime)
	updateBindStatusOverlay(button, bagID, slotID, info, overlayRuntime)
	storeButtonRenderState(
		button,
		bagID,
		slotID,
		texture,
		displayCount,
		locked,
		desaturated,
		quality,
		readable,
		itemLink,
		itemID,
		isFiltered,
		noValue,
		isBound,
		questIsQuestItem,
		questID,
		questIsActive,
		isNewItem,
		isUnusableRecipe,
		overlayVersion,
		fontSignature,
		stackCountLayoutSignature,
		freeSlotSignature
	)
	button._bagsWarbandPendingRenderTexture = nil
	button._bagsWarbandHasPendingRenderTexture = nil
	button:Show()
end

local function ensureButtonCapacity(requiredCount)
	if requiredCount <= #state.buttons then
		return true
	end
	if InCombatLockdown and InCombatLockdown() then
		state.pendingRebuild = true
		return false
	end

	for index = #state.buttons + 1, requiredCount do
		local button = state.buttonPool:Acquire()
		button:SetParent(state.content)
		button:EnableMouseWheel(true)
		button:SetScript("OnMouseWheel", function(_, delta)
			handleScrollWheel(delta)
		end)
		if button.ItemLevelText then
			button.ItemLevelText:SetText("")
			button.ItemLevelText:Hide()
		end
		if button.ItemUpgradeText then
			button.ItemUpgradeText:SetText("")
			button.ItemUpgradeText:Hide()
		end
		if button.EquipmentSetIcon then
			button.EquipmentSetIcon:Hide()
		end
		if button.EquipmentSetText then
			button.EquipmentSetText:SetText("")
			button.EquipmentSetText:Hide()
		end
		if button.BindStatusText then
			button.BindStatusText:SetText("")
			button.BindStatusText:Hide()
		end
		state.buttons[index] = button
	end

	return true
end

local function layoutFrame(layoutData, context)
	local buttonSize = getButtonSize()
	local buttonSpacing = getButtonSpacing()
	local columnCount = math.floor((tonumber(addon.GetMaxColumns and addon.GetMaxColumns() or context and context.columnCount) or DEFAULT_COLUMN_COUNT) + 0.5)
	if columnCount < 4 then
		columnCount = 4
	elseif columnCount > 40 then
		columnCount = 40
	end
	local settings = getSettings()
	local currentHeaderCount = 0
	local contentWidth = 1
	local yOffset = 0
	local maxContentWidth = (columnCount * buttonSize) + (math.max(0, columnCount - 1) * buttonSpacing)
	local compactSectionGap = addon.GetCompactCategoryGap and addon.GetCompactCategoryGap() or SECTION_HORIZONTAL_GAP

	applyConfiguredFrameFonts()

	if state.frame and state.frame.Title then
		state.frame.Title:SetText((context and context.label) or (BANK or "Bank"))
	end
	refreshActionBar(context)

	local function getSectionMetrics(section, showSectionHeader, sectionCollapsed)
		local itemCount = #section.slotIndices
		local visibleColumns = math.max(1, math.min(columnCount, itemCount))
		local rows = (itemCount > 0 and not sectionCollapsed) and math.max(1, math.ceil(itemCount / columnCount)) or 0
		local sectionWidth = (visibleColumns * buttonSize) + (math.max(0, visibleColumns - 1) * buttonSpacing)
		local blockHeight = 0
		local textElementID = section and section.groupID and "subcategoryHeader" or "categoryHeader"
		if showSectionHeader then
			blockHeight = blockHeight + SECTION_HEADER_HEIGHT
			local headerWidth = getMeasuredSectionHeaderWidth(section.label, textElementID)
			sectionWidth = math.max(sectionWidth, headerWidth)
		end
		if itemCount > 0 and not sectionCollapsed then
			if showSectionHeader then
				blockHeight = blockHeight + SECTION_CONTENT_TOP_PADDING
			end
			blockHeight = blockHeight + (rows * buttonSize) + (math.max(0, rows - 1) * buttonSpacing)
		end
		return {
			itemCount = itemCount,
			visibleColumns = visibleColumns,
			rows = rows,
			sectionWidth = sectionWidth,
			blockWidth = sectionWidth,
			blockHeight = math.max(blockHeight, showSectionHeader and SECTION_HEADER_HEIGHT or 1),
		}
	end

	local function isCompactable(section, metrics, sectionCollapsed)
		if not (settings.showCategories and addon.GetCompactCategoryLayout and addon.GetCompactCategoryLayout()) then
			return false
		end
		if not section or not section.label or section.id == FREE_SLOTS_SECTION_ID then
			return false
		end
		if not metrics or metrics.itemCount <= 0 then
			return false
		end
		return true
	end

	local function getSectionGroupHeaderColor(section)
		if section and section.groupColor then
			return section.groupColor
		end

		local skin = getActiveFrameSkin()
		if skin and skin.titleColor then
			return {
				skin.titleColor[1] or 1,
				skin.titleColor[2] or 0.82,
				skin.titleColor[3] or 0,
			}
		end

		return { 1, 0.82, 0 }
	end

	local function getSectionCollapsedState(section, showSectionHeader)
		if not showSectionHeader or not section then
			return false
		end

		local collapseID = section.groupCollapseID
		if not collapseID and section.collapsible ~= false then
			collapseID = section.id
		end
		if not collapseID then
			return false
		end

		return isSectionCollapsed(collapseID)
	end

	local function renderSectionGroupHeader(section, headerCount, spacerCount, offsetY, isCollapsed)
		if not section or not section.groupID or not section.groupLabel or section.groupLabel == "" then
			return headerCount, spacerCount, offsetY
		end

		if section.groupSpacerBefore and offsetY > 0 then
			offsetY = offsetY + GROUP_SPACER_TOP_GAP
			spacerCount = spacerCount + 1
			local spacer = acquireGroupSpacer(spacerCount)
			spacer:ClearAllPoints()
			spacer:SetPoint("TOPLEFT", state.content, "TOPLEFT", 0, -offsetY)
			spacer:SetPoint("RIGHT", state.content, "RIGHT", 0, 0)
			if spacer.Line then
				local skin = getActiveFrameSkin()
				spacer.Line:SetColorTexture(unpackSkinColor(skin and skin.dividerColor, 1, 1, 1, 0.08))
			end
			spacer:Show()
			offsetY = offsetY + 1 + GROUP_SPACER_BOTTOM_GAP
		end

		headerCount = headerCount + 1
		local header = acquireSectionHeader(headerCount)
		configureSectionHeader(header, {
			sectionID = section.groupCollapseID,
			label = section.groupLabel,
			color = getSectionGroupHeaderColor(section),
			collapsed = isCollapsed,
			collapsible = section.groupCollapseID ~= nil,
			textElementID = "categoryHeader",
		})
		header:ClearAllPoints()
		header:SetPoint("TOPLEFT", state.content, "TOPLEFT", 0, -offsetY)
		header:SetPoint("RIGHT", state.content, "RIGHT", 0, 0)
		header:Show()

		return headerCount, spacerCount, offsetY + GROUP_HEADER_HEIGHT + GROUP_HEADER_GAP
	end

	local function getGroupedCategoryIndent(section)
		if not (section and section.groupID) then
			return 0
		end
		if not (addon.GetCategoryTreeView and addon.GetCategoryTreeView()) then
			return 0
		end
		return addon.GetCategoryTreeIndent and addon.GetCategoryTreeIndent() or 0
	end

	local function getCategoryContentIndent(section)
		if not (section and section.label) then
			return 0
		end
		if not (addon.GetCategoryTreeView and addon.GetCategoryTreeView()) then
			return 0
		end
		return addon.GetCategoryTreeIndent and addon.GetCategoryTreeIndent() or 0
	end

	local function getCompactSectionContentOffset(section)
		if section and section.groupID then
			return 0
		end
		return getCategoryContentIndent(section)
	end

	local function getCompactSectionBlockWidth(section, metrics)
		if not metrics then
			return buttonSize
		end
		return (metrics.blockWidth or metrics.sectionWidth or buttonSize) + getCompactSectionContentOffset(section)
	end

		local sectionIndex = 1
		local activeGroupID = nil
		local currentSpacerCount = 0
		while sectionIndex <= #layoutData.sections do
			local section = layoutData.sections[sectionIndex]
			local groupCollapsed = section.groupID and section.groupCollapseID and isSectionCollapsed(section.groupCollapseID) or false

			if section.groupID then
				if activeGroupID ~= section.groupID then
					currentHeaderCount, currentSpacerCount, yOffset = renderSectionGroupHeader(section, currentHeaderCount, currentSpacerCount, yOffset, groupCollapsed)
					activeGroupID = section.groupID
				end
		else
				activeGroupID = nil
			end

			if groupCollapsed then
				local collapsedGroupID = section.groupID
				while sectionIndex <= #layoutData.sections do
					local groupedSection = layoutData.sections[sectionIndex]
					if groupedSection.groupID ~= collapsedGroupID then
						break
					end
					for _, mappingIndex in ipairs(groupedSection.slotIndices or {}) do
						local mapping = state.slotMappings[mappingIndex]
						if mapping then
							mapping.sectionCollapsed = true
						end
					end
					sectionIndex = sectionIndex + 1
				end
				if sectionIndex <= #layoutData.sections then
					yOffset = yOffset + SECTION_GAP
				end
			elseif section.groupID and section.groupCombineSubcategories then
				local combinedSlotIndices = {}
				local combinedGroupID = section.groupID
				while sectionIndex <= #layoutData.sections do
					local groupedSection = layoutData.sections[sectionIndex]
					if groupedSection.groupID ~= combinedGroupID or not groupedSection.groupCombineSubcategories then
						break
					end
					for _, mappingIndex in ipairs(groupedSection.slotIndices or {}) do
						local mapping = state.slotMappings[mappingIndex]
						if mapping then
							mapping.sectionCollapsed = false
						end
						combinedSlotIndices[#combinedSlotIndices + 1] = mappingIndex
					end
					sectionIndex = sectionIndex + 1
				end

				local itemCount = #combinedSlotIndices
				if itemCount > 0 then
					local visibleColumns = math.max(1, math.min(columnCount, itemCount))
					local rows = math.max(1, math.ceil(itemCount / columnCount))
					local sectionWidth = (visibleColumns * buttonSize) + (math.max(0, visibleColumns - 1) * buttonSpacing)
					contentWidth = math.max(contentWidth, sectionWidth)

					for visualIndex, mappingIndex in ipairs(combinedSlotIndices) do
						local button = state.buttons[mappingIndex]
						local row = math.floor((visualIndex - 1) / columnCount)
						local column = (visualIndex - 1) % columnCount
						button:SetSize(buttonSize, buttonSize)
						button:ClearAllPoints()
						button:SetPoint(
							"TOPLEFT",
							state.content,
							"TOPLEFT",
							column * (buttonSize + buttonSpacing),
							-(yOffset + (row * (buttonSize + buttonSpacing)))
						)
					end

					yOffset = yOffset + (rows * buttonSize) + (math.max(0, rows - 1) * buttonSpacing)
				end

				if sectionIndex <= #layoutData.sections then
					yOffset = yOffset + SECTION_GAP
				end
			else
				local showSectionHeader = section.label and (settings.showCategories or section.forceHeader)
				local sectionCollapsed = getSectionCollapsedState(section, showSectionHeader)
				local metrics = getSectionMetrics(section, showSectionHeader, sectionCollapsed)
				for _, mappingIndex in ipairs(section.slotIndices or {}) do
					local mapping = state.slotMappings[mappingIndex]
					if mapping then
						mapping.sectionCollapsed = sectionCollapsed
					end
				end

				if isCompactable(section, metrics, sectionCollapsed) then
					local rowSections = {}
					local rowWidth = 0
					local rowHeight = 0
					local rowGroupID = section.groupID
					local rowIndent = getGroupedCategoryIndent(section)
					local rowMaxContentWidth = math.max(buttonSize, maxContentWidth - rowIndent)

					while sectionIndex <= #layoutData.sections do
						local candidate = layoutData.sections[sectionIndex]
						local candidateShowSectionHeader = candidate.label and (settings.showCategories or candidate.forceHeader)
						local candidateGroupCollapsed = candidate.groupID and candidate.groupCollapseID and isSectionCollapsed(candidate.groupCollapseID) or false
						local candidateCollapsed = candidateGroupCollapsed or getSectionCollapsedState(candidate, candidateShowSectionHeader)
						local candidateMetrics = getSectionMetrics(candidate, candidateShowSectionHeader, candidateCollapsed)
						for _, mappingIndex in ipairs(candidate.slotIndices or {}) do
							local mapping = state.slotMappings[mappingIndex]
							if mapping then
								mapping.sectionCollapsed = candidateCollapsed
							end
						end

						if candidateGroupCollapsed or not isCompactable(candidate, candidateMetrics, candidateCollapsed) then
							break
						end

						if candidate.groupID ~= rowGroupID then
							break
						end

						local nextWidth = getCompactSectionBlockWidth(candidate, candidateMetrics)
						if #rowSections > 0 then
							nextWidth = nextWidth + compactSectionGap
						end

						if #rowSections > 0 and (rowWidth + nextWidth) > rowMaxContentWidth then
							break
						end

						rowSections[#rowSections + 1] = {
							section = candidate,
							collapsed = candidateCollapsed,
							metrics = candidateMetrics,
						}
						rowWidth = rowWidth + nextWidth
						rowHeight = math.max(rowHeight, candidateMetrics.blockHeight)
						sectionIndex = sectionIndex + 1
					end

					local blockX = rowIndent
					for _, entry in ipairs(rowSections) do
						local rowSection = entry.section
						local rowMetrics = entry.metrics
						local rowContentOffset = getCompactSectionContentOffset(rowSection)
						local rowBlockWidth = getCompactSectionBlockWidth(rowSection, rowMetrics)

						currentHeaderCount = currentHeaderCount + 1
						local header = acquireSectionHeader(currentHeaderCount)
						configureSectionHeader(header, {
							sectionID = rowSection.id,
							label = rowSection.label,
							color = rowSection.color,
							collapsed = entry.collapsed,
							collapsible = rowSection.collapsible,
							textElementID = rowSection.groupID and "subcategoryHeader" or "categoryHeader",
						})
						header:ClearAllPoints()
						header:SetPoint("TOPLEFT", state.content, "TOPLEFT", blockX, -yOffset)
						header:SetWidth(rowBlockWidth)
						header:Show()

						local buttonYOffset = yOffset + SECTION_HEADER_HEIGHT + SECTION_CONTENT_TOP_PADDING
						for visualIndex, mappingIndex in ipairs(rowSection.slotIndices) do
							local button = state.buttons[mappingIndex]
							local row = math.floor((visualIndex - 1) / columnCount)
							local column = (visualIndex - 1) % columnCount
							button:SetSize(buttonSize, buttonSize)
							button:ClearAllPoints()
							button:SetPoint(
								"TOPLEFT",
								state.content,
								"TOPLEFT",
								blockX + rowContentOffset + (column * (buttonSize + buttonSpacing)),
								-(buttonYOffset + (row * (buttonSize + buttonSpacing)))
							)
						end

						contentWidth = math.max(contentWidth, blockX + rowBlockWidth)
						blockX = blockX + rowBlockWidth + compactSectionGap
					end

					yOffset = yOffset + rowHeight
					if sectionIndex <= #layoutData.sections then
						yOffset = yOffset + SECTION_GAP
					end
				else
					if showSectionHeader then
						currentHeaderCount = currentHeaderCount + 1
						local header = acquireSectionHeader(currentHeaderCount)
						local categoryIndent = getGroupedCategoryIndent(section)
						configureSectionHeader(header, {
							sectionID = section.id,
							label = section.label,
							color = section.color,
							collapsed = sectionCollapsed,
							collapsible = section.collapsible,
							textElementID = section.groupID and "subcategoryHeader" or "categoryHeader",
						})
						header:ClearAllPoints()
						header:SetPoint("TOPLEFT", state.content, "TOPLEFT", categoryIndent, -yOffset)
						header:SetPoint("RIGHT", state.content, "RIGHT", -categoryIndent, 0)
						header:Show()
						yOffset = yOffset + SECTION_HEADER_HEIGHT
					end

					if metrics.itemCount > 0 and not sectionCollapsed then
						local categoryIndent = getCategoryContentIndent(section)
						if showSectionHeader then
							yOffset = yOffset + SECTION_CONTENT_TOP_PADDING
						end
						contentWidth = math.max(contentWidth, categoryIndent + metrics.sectionWidth)

						for visualIndex, mappingIndex in ipairs(section.slotIndices) do
							local button = state.buttons[mappingIndex]
							local row = math.floor((visualIndex - 1) / columnCount)
							local column = (visualIndex - 1) % columnCount
							button:SetSize(buttonSize, buttonSize)
							button:ClearAllPoints()
							button:SetPoint(
								"TOPLEFT",
								state.content,
								"TOPLEFT",
								categoryIndent + (column * (buttonSize + buttonSpacing)),
								-(yOffset + (row * (buttonSize + buttonSpacing)))
							)
						end

						yOffset = yOffset + (metrics.rows * buttonSize) + (math.max(0, metrics.rows - 1) * buttonSpacing)
					end

					if sectionIndex < #layoutData.sections then
						yOffset = yOffset + SECTION_GAP
					end
					sectionIndex = sectionIndex + 1
				end
			end
		end

	for index = currentHeaderCount + 1, #state.sectionHeaders do
		state.sectionHeaders[index]:Hide()
	end
	for index = currentSpacerCount + 1, #state.groupSpacers do
		state.groupSpacers[index]:Hide()
	end

	local contentHeight = math.max(1, yOffset)
	updateScrollFrameLayout(contentWidth, contentHeight)
	applyActiveSkin()

	for index = layoutData.requiredButtonCount + 1, #state.buttons do
		state.buttons[index]:Hide()
	end
end

local function getVisibleContexts()
	return addon.GetVisibleBankContexts and addon.GetVisibleBankContexts() or {}
end

local function findContextByID(contexts, contextID)
	for _, context in ipairs(contexts or {}) do
		if context and context.id == contextID then
			return context
		end
	end

	return nil
end

local function shouldRememberLastBankTab()
	return addon.GetRememberLastBankTab == nil or addon.GetRememberLastBankTab()
end

local function setActiveContextID(contextID, persist)
	state.activeContextID = contextID
	if persist and shouldRememberLastBankTab() then
		getFrameDB().activeContextID = contextID
	end
end

getVisibleContext = function()
	local contexts = getVisibleContexts()
	local rememberLastBankTab = shouldRememberLastBankTab()
	if not rememberLastBankTab then
		getFrameDB().activeContextID = nil
	end

	if #contexts == 0 then
		return nil, contexts
	end

	local preferredContextID = state.activeContextID or (rememberLastBankTab and getFrameDB().activeContextID or nil)
	local context = findContextByID(contexts, preferredContextID) or contexts[1]

	if state.activeContextID ~= (context and context.id or nil) then
		setActiveContextID(context and context.id or nil, false)
	end

	return context, contexts
end

state.isBagInContext = state.isBagInContext or function(context, bagID)
	if not context or type(bagID) ~= "number" then
		return false
	end
	for _, contextBagID in ipairs(context.bagIDs or {}) do
		if contextBagID == bagID then
			return true
		end
	end
	return false
end

state.markBankBagDirty = state.markBankBagDirty or function(bagID)
	if type(bagID) ~= "number" then
		return false
	end

	local context = getVisibleContext()
	local perf = state.getPerfBucket()
	if not state.isBagInContext(context, bagID) then
		perf.dirtyBagsIgnored = (perf.dirtyBagsIgnored or 0) + 1
		return false
	end

	if not state.dirtyBags[bagID] then
		state.dirtyBags[bagID] = true
		state.dirtyBagCount = (state.dirtyBagCount or 0) + 1
		perf.dirtyBagsMarked = (perf.dirtyBagsMarked or 0) + 1
	end

	return true
end

state.hasDirtyBankBagsForContext = state.hasDirtyBankBagsForContext or function(context)
	if not context or (state.dirtyBagCount or 0) <= 0 then
		return false
	end
	for bagID in pairs(state.dirtyBags) do
		if state.isBagInContext(context, bagID) then
			return true
		end
	end
	return false
end

state.clearDirtyBankBags = state.clearDirtyBankBags or function()
	wipeTable(state.dirtyBags)
	state.dirtyBagCount = 0
end

state.contextHasNewItems = state.contextHasNewItems or function(context)
	if not context or not C_NewItems or not C_NewItems.IsNewItem then
		return false
	end
	for _, bagID in ipairs(context.bagIDs or {}) do
		local slotCount = C_Container.GetContainerNumSlots(bagID) or 0
		for slotID = 1, slotCount do
			if C_NewItems.IsNewItem(bagID, slotID) then
				return true
			end
		end
	end
	return false
end

local function isCustomBankContextVisible()
	return state.frame ~= nil
		and state.frame:IsShown()
		and getVisibleContext() ~= nil
end

function addon.PreClickHandleCustomBankTransfer(mouseButton, bagID, slotID)
	if mouseButton ~= "RightButton" or IsModifiedClick() then
		return false
	end

	if not isCustomBankContextVisible() then
		return false
	end

	if type(bagID) ~= "number" or type(slotID) ~= "number" then
		return false
	end

	if not C_Item
		or not C_Item.DoesItemExist
		or (SpellCanTargetItem and SpellCanTargetItem())
		or (SpellCanTargetItemID and SpellCanTargetItemID())
	then
		return false
	end

	local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
	if not itemLocation or not itemLocation:IsValid() or not C_Item.DoesItemExist(itemLocation) then
		return false
	end

	local context = getVisibleContext()
	if not context then
		return false
	end

	local bankType = getBankTypeForContext(context)
	if bankType == nil then
		return false
	end

	if not state.canDepositItemLocationIntoBank(bankType, itemLocation) then
		return false
	end

	if bankType == ACCOUNT_BANK_TYPE and C_Item and C_Item.CanBeRefunded and C_Item.CanBeRefunded(itemLocation) and StaticPopup_Show and Item and C_Item.GetItemGUID and C_Item.GetItemGUID(itemLocation) then
		StaticPopup_Show("ACCOUNT_BANK_DEPOSIT_NO_REFUND_CONFIRM", nil, nil, {
			itemToDeposit = Item:CreateFromItemGUID(C_Item.GetItemGUID(itemLocation)),
			targetItemLocation = nil,
		})
		return true
	end

	C_Container.UseContainerItem(bagID, slotID, nil, bankType, false)
	return true
end

function addon.GetCustomBankItemContextMatchResult(itemLocation)
	if not isCustomBankContextVisible() then
		return nil
	end

	if not itemLocation
		or not C_Item
		or not C_Item.DoesItemExist
		or not C_Item.DoesItemExist(itemLocation)
		or not C_Bank
		or not C_Bank.IsItemAllowedInBankType
		or not ItemButtonUtil
		or not ItemButtonUtil.ItemContextMatchResult
	then
		return nil
	end

	local context = getVisibleContext()
	local bankType = getBankTypeForContext(context)
	if bankType == nil then
		return nil
	end

	if C_Bank.IsItemAllowedInBankType(bankType, itemLocation) then
		return ItemButtonUtil.ItemContextMatchResult.Match
	end

	return ItemButtonUtil.ItemContextMatchResult.Mismatch
end

local function notifyItemContextChanged()
	if ItemButtonUtil and ItemButtonUtil.TriggerEvent and ItemButtonUtil.Event and ItemButtonUtil.Event.ItemContextChanged then
		ItemButtonUtil.TriggerEvent(ItemButtonUtil.Event.ItemContextChanged)
	end
end

local function getTotalSlotCount(context)
	return context and context.totalSlotCount or 0
end

local function updateTabs(contexts, activeContextID)
	if not state.frame or not state.frame.TabButtonsByContextID then
		return
	end

	local visibleTabs = {}
	local selectedTabIndex
	local previousTab

	for _, definition in ipairs(BANK_CONTEXT_TABS) do
		local tab = state.frame.TabButtonsByContextID and state.frame.TabButtonsByContextID[definition.id]
		local context = findContextByID(contexts, definition.id)
		if tab then
			if context then
				tab.contextID = context.id
				tab:SetText(context.label or definition.label)
				PanelTemplates_TabResize(tab, 0)
				tab:ClearAllPoints()
				if previousTab then
					tab:SetPoint("LEFT", previousTab, "RIGHT", 0, 0)
				else
					tab:SetPoint("TOPLEFT", state.frame, "TOPLEFT", FRAME_PADDING - 2, -31)
				end
				tab:Show()
				visibleTabs[#visibleTabs + 1] = tab
				previousTab = tab
				if context.id == activeContextID then
					selectedTabIndex = #visibleTabs
				end
			else
				tab.contextID = nil
				tab:Hide()
			end
		end
	end

	state.frame.Tabs = visibleTabs
	PanelTemplates_SetNumTabs(state.frame, #visibleTabs)
	if #visibleTabs > 0 then
		PanelTemplates_SetTab(state.frame, selectedTabIndex or 1)
	else
		state.frame.selectedTab = nil
	end

	local skin = getActiveFrameSkin()
	for index, tab in ipairs(visibleTabs) do
		applyTabButtonSkin(tab, index == (state.frame.selectedTab or 0), skin)
	end
end

local function saveFramePosition(frame)
	local point, _, relativePoint, x, y = frame:GetPoint(1)
	if not point or not relativePoint then
		return
	end

	local frameDB = getFrameDB()
	frameDB.point = point
	frameDB.relativePoint = relativePoint
	frameDB.x = x
	frameDB.y = y
	frameDB.userPlaced = true
	state.userMoved = true
end

local function applySavedFramePosition(frame)
	local frameDB = getFrameDB()
	if not frameDB.userPlaced then
		return false
	end

	frame:ClearAllPoints()
	frame:SetPoint(
		frameDB.point or DEFAULT_FRAME_POINT.point,
		UIParent,
		frameDB.relativePoint or DEFAULT_FRAME_POINT.relativePoint,
		frameDB.x or DEFAULT_FRAME_POINT.x,
		frameDB.y or DEFAULT_FRAME_POINT.y
	)
	state.userMoved = true
	return true
end

local function createMainFrame()
	if state.frame then
		return state.frame
	end

	local frame = CreateFrame("Frame", "BagsWarbandBankFrame", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		saveFramePosition(self)
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0.05, 0.06, 0.08, 0.94)
	frame:SetBackdropBorderColor(0.35, 0.35, 0.42, 1)
	frame:SetSize(MIN_FRAME_WIDTH, 1)
	frame:Hide()

	local backgroundBackingTexture = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	backgroundBackingTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
	backgroundBackingTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
	backgroundBackingTexture:Hide()
	frame.BackgroundBackingTexture = backgroundBackingTexture

	local backgroundTexture = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	backgroundTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
	backgroundTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
	backgroundTexture:Hide()
	frame.BackgroundTexture = backgroundTexture

	local backgroundShade = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	backgroundShade:SetAllPoints(backgroundTexture)
	backgroundShade:Hide()
	frame.BackgroundShade = backgroundShade

	local customBorderFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	customBorderFrame:SetFrameLevel(frame:GetFrameLevel() + 2)
	customBorderFrame:EnableMouse(false)
	customBorderFrame:Hide()
	frame.CustomBorderFrame = customBorderFrame
	tinsert(UISpecialFrames, "BagsWarbandBankFrame")
	frame:SetScript("OnHide", function()
		if not shouldRememberLastBankTab() then
			state.activeContextID = nil
			getFrameDB().activeContextID = nil
		end
		if C_Bank and C_Bank.CloseBankFrame and addon.AreAnyBankContextsViewable and addon.AreAnyBankContextsViewable() then
			C_Bank.CloseBankFrame()
		end
	end)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING, -10)
	title:SetText(BANK or "Bank")
	frame.Title = title

	local settingsButton = CreateFrame("Button", nil, frame)
	settingsButton:SetSize(18, 18)
	settingsButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PADDING, -8)
	settingsButton:SetHitRectInsets(-4, -4, -4, -4)
	settingsButton:RegisterForClicks("LeftButtonUp")
	settingsButton.Icon = settingsButton:CreateTexture(nil, "ARTWORK")
	settingsButton.Icon:SetPoint("CENTER")
	local hasQuestLogSettingsAtlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("questlog-icon-setting")
	if hasQuestLogSettingsAtlas then
		settingsButton.Icon:SetAtlas("questlog-icon-setting", true)
	else
		settingsButton.Icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
		settingsButton.Icon:SetSize(16, 16)
	end

	local highlight = settingsButton:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetPoint("CENTER", settingsButton.Icon, "CENTER")
	if hasQuestLogSettingsAtlas then
		highlight:SetAtlas("questlog-icon-setting", true)
	else
		highlight:SetTexture("Interface\\Buttons\\UI-OptionsButton")
		highlight:SetSize(16, 16)
	end
	highlight:SetBlendMode("ADD")
	highlight:SetAlpha(0.4)
	settingsButton.HighlightTexture = highlight

	settingsButton:SetScript("OnMouseDown", function(self)
		self.Icon:AdjustPointsOffset(1, -1)
	end)
	settingsButton:SetScript("OnMouseUp", function(self)
		self.Icon:AdjustPointsOffset(-1, 1)
	end)
	settingsButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(SETTINGS, 1, 0.82, 0)
		GameTooltip:Show()
	end)
	settingsButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	settingsButton:SetScript("OnClick", function()
		if addon.ToggleSettings then
			addon.ToggleSettings()
		end
	end)
	frame.SettingsButton = settingsButton

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButtonNoScripts")
	closeButton:SetSize(22, 22)
	closeButton:SetHitRectInsets(-2, -2, -2, -2)
	closeButton:SetScript("OnClick", function()
		if Bags.functions and Bags.functions.HideBankFrame then
			Bags.functions.HideBankFrame()
		else
			frame:Hide()
		end
	end)
	frame.CloseButton = closeButton

	local searchBox = CreateFrame("EditBox", "BagsWarbandBankSearchBox", frame, "BagSearchBoxTemplate")
	searchBox.instructionText = ""
	if searchBox.Instructions then
		searchBox.Instructions:SetText("")
	end
	if ITEM_SEARCHBAR_LIST then
		local alreadyRegistered = false
		for _, barName in ipairs(ITEM_SEARCHBAR_LIST) do
			if barName == "BagsWarbandBankSearchBox" then
				alreadyRegistered = true
				break
			end
		end
		if not alreadyRegistered then
			ITEM_SEARCHBAR_LIST[#ITEM_SEARCHBAR_LIST + 1] = "BagsWarbandBankSearchBox"
		end
	end
	searchBox:SetHeight(20)
	searchBox:SetPoint("TOPLEFT", title, "TOPRIGHT", 18, 2)
	searchBox:SetPoint("TOPRIGHT", settingsButton, "TOPLEFT", -10, -1)
	searchBox:SetScript("OnHide", function(self)
		BagSearch_OnHide(self)
	end)
	searchBox:SetScript("OnTextChanged", function(self, userChanged)
		BagSearch_OnTextChanged(self, userChanged)
	end)
	searchBox:SetScript("OnChar", BagSearch_OnChar)
	frame.SearchBox = searchBox
	refreshHeaderControls()

	frame.TabButtonsByContextID = {}
	frame.Tabs = {}
	for index, definition in ipairs(BANK_CONTEXT_TABS) do
		local tab = CreateFrame("Button", nil, frame, "PanelTopTabButtonTemplate")
		tab:SetID(index)
		tab:SetText(definition.label)
		tab.contextID = definition.id
		tab:SetScript("OnClick", function(self)
			if self.contextID and self.contextID ~= state.activeContextID then
				setActiveContextID(self.contextID, true)
				syncBlizzardBankStateForContextID(self.contextID)
				notifyItemContextChanged()
				if scheduleUpdate then
					scheduleUpdate(true, true, true, "BankTabClick")
				end
			end
		end)
		frame.TabButtonsByContextID[definition.id] = tab
	end

	local actionBar = CreateFrame("Frame", nil, frame)
	actionBar:SetHeight(ACTION_BAR_HEIGHT)
	actionBar:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING, -ACTION_BAR_TOP_OFFSET)
	actionBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PADDING, -ACTION_BAR_TOP_OFFSET)
	frame.ActionBar = actionBar

	local topRow = CreateFrame("Frame", nil, actionBar)
	topRow:SetHeight(ACTION_ROW_HEIGHT)
	topRow:SetPoint("TOPLEFT", actionBar, "TOPLEFT", 0, 0)
	topRow:SetPoint("TOPRIGHT", actionBar, "TOPRIGHT", 0, 0)
	actionBar.TopRow = topRow

	local bottomRow = CreateFrame("Frame", nil, actionBar)
	bottomRow:SetHeight(ACTION_ROW_HEIGHT)
	bottomRow:SetPoint("TOPLEFT", topRow, "BOTTOMLEFT", 0, -ACTION_ROW_GAP)
	bottomRow:SetPoint("TOPRIGHT", topRow, "BOTTOMRIGHT", 0, -ACTION_ROW_GAP)
	actionBar.BottomRow = bottomRow

	local depositButton = CreateFrame("Button", nil, topRow, "UIPanelButtonTemplate")
	depositButton:SetSize(DEPOSIT_BUTTON_WIDTH, ACTION_ROW_HEIGHT)
	depositButton:SetPoint("LEFT", topRow, "LEFT", 0, 0)
	depositButton:SetText(CHARACTER_BANK_DEPOSIT_BUTTON_LABEL or "Deposit All Reagents")
	depositButton:SetScript("OnClick", function()
		local context = getVisibleContext()
		autoDepositItemsIntoContextBank(context)
	end)
	actionBar.DepositButton = depositButton

	local purchaseTabButton = createBankTabPurchaseButton(topRow)
	purchaseTabButton:SetSize(132, ACTION_ROW_HEIGHT)
	purchaseTabButton:SetPoint("RIGHT", topRow, "RIGHT", 0, 0)
	purchaseTabButton:Hide()
	actionBar.PurchaseTabButton = purchaseTabButton

	local includeReagentsCheckbox = CreateFrame("CheckButton", nil, topRow, "BankPanelCheckboxTemplate")
	Mixin(includeReagentsCheckbox, BankPanelIncludeReagentsCheckboxMixin)
	includeReagentsCheckbox:SetPoint("LEFT", depositButton, "RIGHT", 10, 0)
	includeReagentsCheckbox.text = BANK_DEPOSIT_INCLUDE_REAGENTS_CHECKBOX_LABEL or "Include reagents"
	includeReagentsCheckbox.fontObject = GameFontHighlightSmall
	includeReagentsCheckbox.textWidth = 150
	includeReagentsCheckbox.maxTextLines = 2
	includeReagentsCheckbox:SetScript("OnShow", includeReagentsCheckbox.OnShow)
	includeReagentsCheckbox:SetScript("OnClick", includeReagentsCheckbox.OnClick)
	if includeReagentsCheckbox.Text then
		includeReagentsCheckbox.Text:SetText(includeReagentsCheckbox.text)
		includeReagentsCheckbox.Text:SetScript("OnMouseUp", function()
			includeReagentsCheckbox:Click()
		end)
	end
	actionBar.IncludeReagentsCheckbox = includeReagentsCheckbox

	local depositMoneyButton = CreateFrame("Button", nil, bottomRow, "UIPanelButtonTemplate")
	depositMoneyButton:SetSize(MONEY_BUTTON_WIDTH, ACTION_ROW_HEIGHT)
	depositMoneyButton:SetPoint("RIGHT", bottomRow, "RIGHT", 0, 0)
	depositMoneyButton:SetText(DEPOSIT or "Deposit")
	depositMoneyButton:SetScript("OnClick", function()
		local context = getVisibleContext()
		toggleMoneyTransferPopup("BANK_MONEY_DEPOSIT", "BANK_MONEY_WITHDRAW", context)
	end)
	actionBar.DepositMoneyButton = depositMoneyButton

	local withdrawMoneyButton = CreateFrame("Button", nil, bottomRow, "UIPanelButtonTemplate")
	withdrawMoneyButton:SetSize(MONEY_BUTTON_WIDTH, ACTION_ROW_HEIGHT)
	withdrawMoneyButton:SetPoint("RIGHT", depositMoneyButton, "LEFT", -6, 0)
	withdrawMoneyButton:SetText(WITHDRAW or "Withdraw")
	withdrawMoneyButton:SetScript("OnClick", function()
		local context = getVisibleContext()
		toggleMoneyTransferPopup("BANK_MONEY_WITHDRAW", "BANK_MONEY_DEPOSIT", context)
	end)
	actionBar.WithdrawMoneyButton = withdrawMoneyButton

	local warbandGoldText = bottomRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	warbandGoldText:SetPoint("LEFT", bottomRow, "LEFT", 0, 0)
	warbandGoldText:SetPoint("RIGHT", withdrawMoneyButton, "LEFT", -12, 0)
	warbandGoldText:SetJustifyH("LEFT")
	warbandGoldText:SetWordWrap(false)
	warbandGoldText:SetText("")
	actionBar.WarbandGoldText = warbandGoldText

	local divider = frame:CreateTexture(nil, "BORDER")
	divider:SetColorTexture(1, 1, 1, 0.08)
	divider:SetHeight(1)
	divider:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING, -HEADER_HEIGHT)
	divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PADDING, -HEADER_HEIGHT)
	frame.Divider = divider

	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame.scrollBarHideable = true
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetClipsChildren(true)
	UIPanelScrollFrame_OnLoad(scrollFrame)
	if scrollFrame.ScrollBar then
		scrollFrame.ScrollBar.scrollStep = BUTTON_SIZE + BUTTON_SPACING
	end
	frame.ScrollFrame = scrollFrame

	local content = CreateFrame("Frame", nil, scrollFrame)
	function content:IsCombinedBagContainer()
		return true
	end
	scrollFrame:SetScrollChild(content)
	frame.Content = content
	installFrameDropReceiver(frame, true)
	installFrameDropReceiver(scrollFrame, true)
	installFrameDropReceiver(content, true)

	state.frame = frame
	state.scrollFrame = scrollFrame
	state.content = content
	state.buttonPool = CreateFramePool("ItemButton", content, "BagsItemButtonTemplate")

	if not applySavedFramePosition(frame) then
		frame:SetPoint(
			DEFAULT_FRAME_POINT.point,
			UIParent,
			DEFAULT_FRAME_POINT.relativePoint,
			DEFAULT_FRAME_POINT.x,
			DEFAULT_FRAME_POINT.y
		)
	end

	applyConfiguredFrameFonts()
	applyActiveSkin()

	return frame
end

local function rebuildLayout(context, contexts)
	if not state.frame then
		createMainFrame()
	end
	if InCombatLockdown and InCombatLockdown() then
		state.pendingRebuild = true
		return false
	end

	local layoutData = buildLayoutData(context)
	if not ensureButtonCapacity(layoutData.requiredButtonCount) then
		return false
	end

	layoutFrame(layoutData, context)
	updateTabs(contexts or {}, context and context.id or nil)
	local overlayRuntime = getOverlayRuntimeConfig()
	local textAppearance = getResolvedTextAppearance("overlays")
	local fontSignature = getItemButtonTextAppearanceSignature(textAppearance)
	local tooltipOwner = GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() or nil
	local forceDynamicUpdate = state.forceDynamicRefresh
	local stackCountLayoutSignature = state.getStackCountLayoutSignature()

	for index = 1, layoutData.requiredButtonCount do
		local mapping = state.slotMappings[index]
		local button = state.buttons[index]
		if button._bagsWarbandBagID ~= mapping.bagID or button._bagsWarbandSlotID ~= mapping.slotID then
			button:Initialize(mapping.bagID, mapping.slotID)
			button._bagsWarbandBagID = mapping.bagID
			button._bagsWarbandSlotID = mapping.slotID
		end
		updateButtonData(button, mapping, overlayRuntime, textAppearance, fontSignature, tooltipOwner, forceDynamicUpdate, stackCountLayoutSignature)
	end

	state.currentLayoutCount = layoutData.requiredButtonCount
	state.currentTotalSlotCount = layoutData.totalSlotCount
	state.contextSignature = getContextSignature(context)
	state.pendingRebuild = false
	state.pendingRefresh = false
	state.forceDynamicRefresh = false
	state.currentTextAppearanceSignature = fontSignature
	return true
end

local function refreshButtons(context, contexts)
	if not state.layoutData then
		return rebuildLayout(context, contexts)
	end

	if state.frame and state.frame.Title then
		state.frame.Title:SetText((context and context.label) or (BANK or "Bank"))
	end
	refreshHeaderControls()
	updateTabs(contexts or {}, context and context.id or nil)
	refreshActionBar(context)
	local desiredSkinSignature = addon.GetSkinSignature and addon.GetSkinSignature() or nil
	if state.currentSkinSignature ~= desiredSkinSignature then
		applyActiveSkin()
	end

	local overlayRuntime = getOverlayRuntimeConfig()
	local textAppearance = getResolvedTextAppearance("overlays")
	local fontSignature = getItemButtonTextAppearanceSignature(textAppearance)
	if state.currentTextAppearanceSignature ~= nil and state.currentTextAppearanceSignature ~= fontSignature then
		return rebuildLayout(context, contexts)
	end
	local tooltipOwner = GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner() or nil
	local forceDynamicUpdate = state.forceDynamicRefresh
	local stackCountLayoutSignature = state.getStackCountLayoutSignature()

	for index = 1, state.currentLayoutCount or 0 do
		updateButtonData(
			state.buttons[index],
			state.slotMappings[index],
			overlayRuntime,
			textAppearance,
			fontSignature,
			tooltipOwner,
			forceDynamicUpdate,
			stackCountLayoutSignature
		)
	end

	state.pendingRefresh = false
	state.forceDynamicRefresh = false
	state.currentTextAppearanceSignature = fontSignature
	return true
end

function Bags.functions.PositionBankFrame()
	if not state.frame or state.userMoved then
		return
	end

	local anchor = addon.GetCustomBagsAnchorTargetFrame and addon.GetCustomBagsAnchorTargetFrame() or nil
	if not anchor and addon.GetBankAnchorTargetFrame then
		anchor = addon.GetBankAnchorTargetFrame()
	end
	state.frame:ClearAllPoints()
	if anchor then
		state.frame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -CLUSTER_GAP, 0)
	else
		state.frame:SetPoint(
			DEFAULT_FRAME_POINT.point,
			UIParent,
			DEFAULT_FRAME_POINT.relativePoint,
			DEFAULT_FRAME_POINT.x,
			DEFAULT_FRAME_POINT.y
		)
	end
end

Bags.functions.PositionWarbandBankFrame = Bags.functions.PositionBankFrame

function addon.GetCustomBankAnchorTargetFrame()
	if not state.frame or not state.initialized then
		return nil
	end
	if state.frame:IsShown() or (addon.AreAnyBankContextsViewable and addon.AreAnyBankContextsViewable()) then
		return state.frame
	end
	return nil
end

local function shouldShowFrame(context)
	return addon.Bags and addon.Bags.IsEnabled and addon.Bags.IsEnabled() and context ~= nil
end

local function shouldProcessVisibleUpdates(context)
	if state.frame and state.frame:IsShown() then
		return true
	end

	return shouldShowFrame(context or getVisibleContext())
end

local function setActiveEventRegistration(enabled)
	if not state.eventFrame then
		return
	end

	enabled = not not enabled
	if state.activeEventsRegistered == enabled then
		return
	end

	state.activeEventsRegistered = enabled
	for _, eventName in ipairs(ACTIVE_EVENTS) do
		if enabled then
			state.eventFrame:RegisterEvent(eventName)
		else
			state.eventFrame:UnregisterEvent(eventName)
		end
	end
	for _, entry in ipairs(ACTIVE_UNIT_EVENTS) do
		if enabled then
			state.eventFrame:RegisterUnitEvent(entry.name, entry.unit)
		else
			state.eventFrame:UnregisterEvent(entry.name)
		end
	end
end

local function processUpdate()
	if not state.initialized or not (addon.Bags and addon.Bags.IsEnabled and addon.Bags.IsEnabled()) then
		return
	end

	local context, contexts = getVisibleContext()
	local shouldBeVisible = shouldShowFrame(context)
	local wasVisible = state.frame and state.frame:IsShown()
	local openingFrame = shouldBeVisible and not wasVisible
	local previousContextSignature = state.contextSignature
	local currentContextSignature = getContextSignature(context)
	local contextChanged = previousContextSignature ~= currentContextSignature
	local needsRebuild = state.pendingRebuild
		or state.layoutData == nil
		or contextChanged
		or state.currentTotalSlotCount ~= getTotalSlotCount(context)
		or openingFrame
	local needsRefresh = state.pendingRefresh or state.forceDynamicRefresh

	if openingFrame then
		resetOpenSessionNewItems()
	end

	local updateApplied = true
	if shouldBeVisible then
		syncBlizzardBankState(context)
		if needsRebuild then
			updateApplied = rebuildLayout(context, contexts)
			if updateApplied then state.countReason(state.getPerfBucket().rebuilds, state.consumeReasons(state.pendingRebuildReasons)) end
		elseif needsRefresh then
			updateApplied = refreshButtons(context, contexts)
			if updateApplied then state.countReason(state.getPerfBucket().refreshes, state.consumeReasons(state.pendingRefreshReasons)) end
		else
			refreshActionBar(context)
		end
	end

	if updateApplied and needsRebuild then
		state.clearDirtyBankBags()
	end

	if shouldBeVisible then
		if updateApplied and not state.userMoved then
			Bags.functions.PositionBankFrame()
		end
		if state.frame then
			state.frame:Show()
		end
		if (openingFrame or contextChanged) and Bags.functions.RequestLayoutUpdate then
			local perf = state.getPerfBucket()
			perf.crossBackpackRefreshRequests = (perf.crossBackpackRefreshRequests or 0) + 1
			Bags.functions.RequestLayoutUpdate(false, true)
		end
	else
		if state.frame then
			state.frame:Hide()
		end
	end

	setActiveEventRegistration(shouldBeVisible)
end

scheduleUpdate = function(requestRefresh, requestRebuild, forceWhenHidden, reason)
	local perf = state.getPerfBucket()
	state.countReason(perf.schedule, reason)
	if requestRebuild then
		state.pendingRebuild = true
		state.addPendingReason(state.pendingRebuildReasons, reason)
		state.countReason(perf.rebuildRequests, reason)
	end
	if requestRefresh then
		state.pendingRefresh = true
		state.addPendingReason(state.pendingRefreshReasons, reason)
		state.countReason(perf.refreshRequests, reason)
	end

	if not forceWhenHidden and not shouldProcessVisibleUpdates() then
		state.countReason(perf.skips, "hidden:" .. tostring(reason or "unknown"))
		return
	end

	if state.updateScheduled then
		state.countReason(perf.skips, "alreadyScheduled:" .. tostring(reason or "unknown"))
		return
	end
	state.updateScheduled = true
	RunNextFrame(function()
		state.updateScheduled = false
		processUpdate()
	end)
end

function Bags.functions.RequestBankLayoutUpdate(requestRebuild, forceWhenHidden)
	scheduleUpdate(true, requestRebuild, forceWhenHidden, requestRebuild and "api:rebuild" or "api:refresh")
end

Bags.functions.RequestWarbandBankLayoutUpdate = Bags.functions.RequestBankLayoutUpdate

function Bags.functions.RefreshWarbandBankSearchState()
	if not state.frame or not state.frame:IsShown() then
		return
	end

	local buttons = state.buttons or {}
	for index = 1, state.currentLayoutCount or 0 do
		local button = buttons[index]
		if button and button:IsShown() then
			local bagID = button:GetBagID()
			local slotID = button:GetID()
			local info = C_Container.GetContainerItemInfo(bagID, slotID)
			local isFiltered = info and info.isFiltered
			if button._bagsWarbandRenderFiltered ~= isFiltered then
				updateButtonSearchState(button, isFiltered)
			end
		end
	end
end

function Bags.functions.HideBankFrame()
	if state.frame then
		state.frame:Hide()
	end
	setActiveEventRegistration(false)
	Bags.functions.RestoreDefaultBankFrames()
end

function Bags.functions.EnableBank()
	if not (addon.Bags and addon.Bags.IsEnabled and addon.Bags.IsEnabled()) then
		return
	end
	if addon.GetUseIntegratedBank and not addon.GetUseIntegratedBank() then
		Bags.functions.RestoreDefaultBankFrames()
		return
	end
	if state.initialized then
		detachDefaultBankFrames()
		setActiveEventRegistration(shouldProcessVisibleUpdates())
		scheduleUpdate(true, true, true, "EnableBank")
		return
	end

	detachDefaultBankFrames()
	state.initialized = true
	state.pendingRebuild = true
	setActiveEventRegistration(shouldProcessVisibleUpdates())
	scheduleUpdate(true, true, true, "EnableBank")
end

local eventFrame = state.eventFrame or CreateFrame("Frame")
state.eventFrame = eventFrame
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("BANKFRAME_CLOSED")
eventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		if addon.Bags and addon.Bags.IsEnabled and addon.Bags.IsEnabled() then
			addon.Bags.functions.Enable()
		end
		eventFrame:UnregisterEvent("PLAYER_LOGIN")
		return
	end

	if addon.GetUseIntegratedBank and not addon.GetUseIntegratedBank() then
		Bags.functions.RestoreDefaultBankFrames()
		return
	end

	if not state.initialized or not (addon.Bags and addon.Bags.IsEnabled and addon.Bags.IsEnabled()) then
		return
	end

	if event == "PLAYER_REGEN_ENABLED" then
		scheduleUpdate(state.pendingRefresh, state.pendingRebuild, false, "PLAYER_REGEN_ENABLED")
	elseif event == "BANKFRAME_OPENED" then
		clearTooltipDerivedItemFlagsCache()
		detachDefaultBankFrames()
		addon.UpdateWarbandGold()
		local context = getVisibleContext()
		syncBlizzardBankState(context, true)
		notifyItemContextChanged()
		scheduleUpdate(true, true, true, "BANKFRAME_OPENED")
	elseif event == "BANKFRAME_CLOSED" then
		state.clearDirtyBankBags()
		StaticPopup_Hide("ACCOUNT_BANK_DEPOSIT_ALL_NO_REFUND_CONFIRM")
		StaticPopup_Hide("BANK_MONEY_DEPOSIT")
		StaticPopup_Hide("BANK_MONEY_WITHDRAW")
		notifyItemContextChanged()
		scheduleUpdate(true, true, true, "BANKFRAME_CLOSED")
	elseif event == "BAG_UPDATE" then
		state.markBankBagDirty(...)
	elseif event == "BAG_UPDATE_DELAYED" then
		if state.categoryTransferQueue then
			state.scheduleCategoryTransferQueue(0)
		end
		local perf = state.getPerfBucket()
		perf.dirtyBagDelayedEvents = (perf.dirtyBagDelayedEvents or 0) + 1
		local context = getVisibleContext()
		if state.hasDirtyBankBagsForContext(context) then
			scheduleUpdate(true, true, false, "BAG_UPDATE_DELAYED:dirtyBankBag")
		else
			state.countReason(perf.skips, "BAG_UPDATE_DELAYED:noActiveBankDirtyBag")
		end
	elseif event == "BAG_NEW_ITEMS_UPDATED" then
		local perf = state.getPerfBucket()
		perf.newItemEvents = (perf.newItemEvents or 0) + 1
		local context = getVisibleContext()
		if state.pendingRebuild then
			scheduleUpdate(true, false, false, "BAG_NEW_ITEMS_UPDATED:alreadyPendingRebuild")
		elseif state.contextHasNewItems(context) then
			scheduleUpdate(true, true, false, "BAG_NEW_ITEMS_UPDATED:bankContextHasNewItems")
		else
			perf.newItemEventsSkippedNoBankNewItems = (perf.newItemEventsSkippedNoBankNewItems or 0) + 1
			state.countReason(perf.skips, "BAG_NEW_ITEMS_UPDATED:noBankContextNewItems")
		end
	elseif event == "UNIT_INVENTORY_CHANGED" or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_LEVEL_UP" then
		local usage = addon.GetCategoryRuleContextUsage and addon.GetCategoryRuleContextUsage() or nil
		if doesRuleUsageDependOnPlayerState(usage) then
			bumpPlayerRuleRevision()
			scheduleUpdate(true, true, false, event)
		else
			scheduleUpdate(true, false, false, event)
		end
	elseif event == "INVENTORY_SEARCH_UPDATE" then
		if Bags.functions.RefreshWarbandBankSearchState then
			Bags.functions.RefreshWarbandBankSearchState()
		end
	elseif event == "TOYS_UPDATED" or event == "NEW_TOY_ADDED" then
		clearTooltipDerivedItemFlagsCache()
		scheduleUpdate(true, false, false, event)
	elseif event == "EQUIPMENT_SETS_CHANGED" then
		local usage = addon.GetCategoryRuleContextUsage and addon.GetCategoryRuleContextUsage() or nil
		if usage and usage.isEquipmentSet then
			wipeTable(state.slotCategoryCache)
			scheduleUpdate(true, true, false, "EQUIPMENT_SETS_CHANGED")
		end
	elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" then
		scheduleUpdate(true, false, false, event)
	elseif event == "BANK_TABS_CHANGED" or event == "BANK_TAB_SETTINGS_UPDATED" then
		notifyItemContextChanged()
		scheduleUpdate(true, true, false, event)
	elseif event == "PLAYER_MONEY" then
		scheduleUpdate(true, false, false, "PLAYER_MONEY")
	elseif event == "ACCOUNT_MONEY" then
		addon.UpdateWarbandGold()
		scheduleUpdate(true, false, false, "ACCOUNT_MONEY")
	elseif event == "ITEM_LOCK_CHANGED" or event == "BAG_UPDATE_COOLDOWN" then
		if state.categoryTransferQueue then
			state.scheduleCategoryTransferQueue(0)
		end
		if event == "BAG_UPDATE_COOLDOWN" then
			state.forceDynamicRefresh = true
		end
		scheduleUpdate(true, false, false, event)
	end
end)
