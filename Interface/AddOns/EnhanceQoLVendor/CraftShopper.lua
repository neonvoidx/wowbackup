-- Example file
-- luacheck: globals AUCTION_HOUSE_HEADER_ITEM NEED SEARCH

local parentAddonName = "EnhanceQoL"
local _, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local f = CreateFrame("Frame")
local ICON_PATH = "Interface\\AddOns\\" .. parentAddonName .. "\\Icons\\"

addon.Vendor = addon.Vendor or {}
addon.Vendor.CraftShopper = addon.Vendor.CraftShopper or {}
addon.Vendor.CraftShopper.items = addon.Vendor.CraftShopper.items or {}
addon.Vendor.CraftShopper.multipliers = addon.Vendor.CraftShopper.multipliers or {}

local isRecraftTbl = { false, true } -- erst normale, dann Recrafts

local SCAN_DELAY = 0.3
local pendingScan
local pendingAHShowScan
local scanRunning
local pendingPurchase -- data for a running AH commodities purchase
local lastPurchaseItemID -- itemID of the last confirmed commodities purchase
local ahCache = {} -- [itemID] = true/false
local purchasedItems = {} -- [itemID] = true for items already bought via quick buy

local ShowCraftShopperFrameIfNeeded -- forward declaration
local BuildShoppingList -- forward declaration for early users
local createCrafterMultiplyFrame -- forward declaration
local EnsureCraftShopperProfessionsUI -- forward declaration
local RefreshMultiplyUIState -- forward declaration
local craftShopperCheckboxHooksInstalled = false
local professionsFrameHooksInstalled = false
local schematicFormHooksInstalled = false
local schematicFormMixinHooksInstalled = false

local CRAFT_SHOPPER_QUALITY_LOWEST = "lowest"
local CRAFT_SHOPPER_QUALITY_HIGHEST = "highest"
local craftShopperQualityOrder = {
	CRAFT_SHOPPER_QUALITY_LOWEST,
	CRAFT_SHOPPER_QUALITY_HIGHEST,
}
local craftShopperQualityList = {
	[CRAFT_SHOPPER_QUALITY_LOWEST] = L["vendorCraftShopperReagentQualityLowest"],
	[CRAFT_SHOPPER_QUALITY_HIGHEST] = L["vendorCraftShopperReagentQualityHighest"],
}

local function IsCraftShopperEnabled() return addon.db and addon.db["vendorCraftShopperEnable"] end

local function ShouldIncludeWarbandBank()
	return addon.db and addon.db["vendorCraftShopperIncludeWarbandBank"] == true
end

local function GetCraftShopperReagentQualityMode()
	if addon.db and addon.db["vendorCraftShopperReagentQuality"] == CRAFT_SHOPPER_QUALITY_LOWEST then return CRAFT_SHOPPER_QUALITY_LOWEST end
	return CRAFT_SHOPPER_QUALITY_HIGHEST
end

local function GetTrackRecipeCheckbox()
	if ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm and ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckbox then
		return ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckbox
	end
end

local function HasTrackedRecipes()
	for _, isRecraft in ipairs(isRecraftTbl) do
		local recipes = C_TradeSkillUI.GetRecipesTracked(isRecraft)
		if recipes and #recipes > 0 then return true end
	end
	return false
end

local heavyEvents = {
	"BAG_UPDATE_DELAYED",
	"CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE",
	"AUCTION_HOUSE_SHOW",
	"AUCTION_HOUSE_CLOSED",
	"ADDON_LOADED",
	"TRADE_SKILL_SHOW",
	"TRADE_SKILL_CLOSE",
}

local heavyEventsRegistered = false

local function RegisterHeavyEvents()
	if heavyEventsRegistered then return end
	heavyEventsRegistered = true
	for _, event in ipairs(heavyEvents) do
		f:RegisterEvent(event)
	end
end

-- Remove stored multipliers for recipes that are no longer tracked
local function CleanupUntrackedMultipliers()
	local tracked = {}
	for _, isRecraft in ipairs(isRecraftTbl) do
		local recipes = C_TradeSkillUI.GetRecipesTracked(isRecraft) or {}
		for _, recipeID in ipairs(recipes) do
			tracked[recipeID] = true
		end
	end
	local removed = false
	for recipeID, _ in pairs(addon.Vendor.CraftShopper.multipliers or {}) do
		if not tracked[recipeID] then
			addon.Vendor.CraftShopper.multipliers[recipeID] = nil
			removed = true
		end
	end
	if removed then
		-- Rebuild immediately (not gated by resting) to reflect changes
		addon.Vendor.CraftShopper.items = BuildShoppingList()
		if addon.Vendor.CraftShopper.frame then addon.Vendor.CraftShopper.frame:Refresh() end
		ShowCraftShopperFrameIfNeeded()
	end
end

local function UnregisterHeavyEvents()
	if not heavyEventsRegistered then return end
	heavyEventsRegistered = false
	for _, event in ipairs(heavyEvents) do
		f:UnregisterEvent(event)
	end
	f:UnregisterEvent("COMMODITY_PRICE_UPDATED")
	f:UnregisterEvent("COMMODITY_PURCHASE_FAILED")
	f:UnregisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
	f:UnregisterEvent("AUCTION_HOUSE_SHOW_ERROR")
end

-- Helpers to manage mini-frame state
local function GetCurrentRecipeID()
	local recipeID
	if
		ProfessionsFrame
		and ProfessionsFrame.CraftingPage
		and ProfessionsFrame.CraftingPage.SchematicForm
		and ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo
		and ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID
	then
		recipeID = ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID
	elseif C_TradeSkillUI and C_TradeSkillUI.GetSelectedRecipeID then
		recipeID = C_TradeSkillUI.GetSelectedRecipeID()
	end
	return recipeID
end

local function ShouldShowMultiplyFrame()
	if not IsCraftShopperEnabled() then return false end
	local checkbox = GetTrackRecipeCheckbox()
	if checkbox and checkbox:IsShown() then return true end
	if not ProfessionsFrame or not ProfessionsFrame:IsShown() then return false end
	if not ProfessionsFrame.CraftingPage or not ProfessionsFrame.CraftingPage:IsShown() then return false end

	local form = ProfessionsFrame.CraftingPage.SchematicForm
	if not form or not form:IsShown() then return false end
	if not (form.currentRecipeInfo and form.currentRecipeInfo.recipeID ~= nil) then return false end

	local transaction = form.GetTransaction and form:GetTransaction()
	if transaction and transaction.HasReagentSlots and not transaction:HasReagentSlots() then return false end

	return true
end

local function IsRecipeTrackedAny(recipeID)
	if not recipeID or not C_TradeSkillUI or not C_TradeSkillUI.IsRecipeTracked then return false end
	local ok, tracked = pcall(C_TradeSkillUI.IsRecipeTracked, recipeID, false)
	if ok and tracked then return true end
	local ok2, tracked2 = pcall(C_TradeSkillUI.IsRecipeTracked, recipeID, true)
	return ok2 and tracked2 or false
end

local function UpdateMultiplyFrameState()
	local frame = _G.EQOLCrafterMultiply
	if not frame or not frame.ok or not frame.editBox then return end
	local txt = frame.editBox:GetText() or ""
	local rid = GetCurrentRecipeID()
	local isTracked = IsRecipeTrackedAny(rid)
	if txt == "" then
		frame.ok:SetText(isTracked and PROFESSIONS_UNTRACK_RECIPE or TRACK_ACHIEVEMENT)
	else
		if frame.autoFilled then
			frame.ok:SetText(PROFESSIONS_UNTRACK_RECIPE)
		else
			frame.ok:SetText(TRACK_ACHIEVEMENT)
		end
	end
end

local function EnsureMultiplyFrameExists()
	if _G.EQOLCrafterMultiply then return _G.EQOLCrafterMultiply end
	if not IsCraftShopperEnabled() then return nil end
	local form = ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
	if not form then return nil end
	if createCrafterMultiplyFrame then return createCrafterMultiplyFrame() end
end

RefreshMultiplyUIState = function()
	local checkbox = GetTrackRecipeCheckbox()
	if checkbox and checkbox.SetAlpha then checkbox:SetAlpha(IsCraftShopperEnabled() and 0 or 1) end

	local frame = _G.EQOLCrafterMultiply or EnsureMultiplyFrameExists()
	if frame then
		if ShouldShowMultiplyFrame() then
			frame:Show()
		else
			frame:Hide()
		end
	end

	if UpdateMultiplyFrameState then UpdateMultiplyFrameState() end
end

local function HookCraftShopperCheckboxIfNeeded()
	if craftShopperCheckboxHooksInstalled or not IsCraftShopperEnabled() then return end
	local checkbox = GetTrackRecipeCheckbox()
	if not checkbox or not checkbox.HookScript then return end

	checkbox:HookScript("OnShow", function()
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	end)

	checkbox:HookScript("OnHide", function()
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	end)

	craftShopperCheckboxHooksInstalled = true
end

local function HookSchematicFormStateIfNeeded()
	if schematicFormHooksInstalled then return end
	local form = ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
	if not form then return end

	if form.HookScript then
		form:HookScript("OnShow", function()
			if RefreshMultiplyUIState then RefreshMultiplyUIState() end
		end)
		form:HookScript("OnHide", function()
			if RefreshMultiplyUIState then RefreshMultiplyUIState() end
		end)
	end

	if hooksecurefunc then
		hooksecurefunc(form, "Init", function()
			if RefreshMultiplyUIState then RefreshMultiplyUIState() end
		end)
		hooksecurefunc(form, "Refresh", function()
			if RefreshMultiplyUIState then RefreshMultiplyUIState() end
		end)
	end

	schematicFormHooksInstalled = true
end

local function HookSchematicFormMixinIfNeeded()
	if schematicFormMixinHooksInstalled then return end
	if not hooksecurefunc or not ProfessionsRecipeSchematicFormMixin then return end

	local function onSchematicUpdate(form)
		if not IsCraftShopperEnabled() then return end
		if not ProfessionsFrame or not ProfessionsFrame.CraftingPage or form ~= ProfessionsFrame.CraftingPage.SchematicForm then return end
		if not _G.EQOLCrafterMultiply and createCrafterMultiplyFrame then createCrafterMultiplyFrame() end
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	end

	hooksecurefunc(ProfessionsRecipeSchematicFormMixin, "Init", onSchematicUpdate)
	hooksecurefunc(ProfessionsRecipeSchematicFormMixin, "Refresh", onSchematicUpdate)
	hooksecurefunc(ProfessionsRecipeSchematicFormMixin, "OnShow", onSchematicUpdate)
	hooksecurefunc(ProfessionsRecipeSchematicFormMixin, "OnHide", onSchematicUpdate)

	schematicFormMixinHooksInstalled = true
end

local function HookProfessionsFrameVisibilityIfNeeded()
	if professionsFrameHooksInstalled then return end
	if not ProfessionsFrame or not ProfessionsFrame.HookScript then return end

	ProfessionsFrame:HookScript("OnShow", function()
		if not IsCraftShopperEnabled() then return end
		EnsureCraftShopperProfessionsUI()
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	end)

	ProfessionsFrame:HookScript("OnHide", function()
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	end)

	professionsFrameHooksInstalled = true
end

EnsureCraftShopperProfessionsUI = function()
	if not IsCraftShopperEnabled() then return end
	if IsAddOnLoaded and IsAddOnLoaded("Blizzard_Professions") then
		HookSchematicFormMixinIfNeeded()
		HookProfessionsFrameVisibilityIfNeeded()
		HookSchematicFormStateIfNeeded()
		if not EQOLCrafterMultiply and createCrafterMultiplyFrame then createCrafterMultiplyFrame() end
		HookCraftShopperCheckboxIfNeeded()
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	else
		f:RegisterEvent("ADDON_LOADED")
	end
end

local function isAHBuyable(itemID)
	if ahCache[itemID] ~= nil then return ahCache[itemID] end
	local buyable = true
	local data = C_TooltipInfo.GetItemByID(itemID)
	if data and data.lines then
		for _, line in ipairs(data.lines) do
			if (line.type == 20 and line.leftText == ITEM_BIND_ON_EQUIP) or (line.type == 0 and line.leftText == ITEM_CONJURED) then
				buyable = false
				break
			end
		end
	end
	ahCache[itemID] = buyable
	return buyable
end
local schemCache = {} -- [recipeID] = schematic
local schemCacheRecraft = {} -- [recipeID] = schematic

local function getSchematic(recipeID, isRecraft)
	if isRecraft and schemCacheRecraft[recipeID] then return schemCacheRecraft[recipeID] end
	if not isRecraft and schemCache[recipeID] then return schemCache[recipeID] end
	local s = C_TradeSkillUI.GetRecipeSchematic(recipeID, isRecraft)
	if isRecraft then
		schemCacheRecraft[recipeID] = s
	else
		schemCache[recipeID] = s
	end
	return s
end

local function GetTrackedReagentItemID(slot)
	if not slot or not slot.reagents then return nil end
	local preferHighest = GetCraftShopperReagentQualityMode() == CRAFT_SHOPPER_QUALITY_HIGHEST

	-- Profession quality variants are ordered ascending. Pick the configured end
	-- first, then fall back to the opposite direction if a slot is sparse.
	if preferHighest then
		for index = #slot.reagents, 1, -1 do
			local reagent = slot.reagents[index]
			if reagent and reagent.itemID and reagent.itemID ~= 0 then return reagent.itemID end
		end
	else
		for _, reagent in ipairs(slot.reagents) do
			if reagent and reagent.itemID and reagent.itemID ~= 0 then return reagent.itemID end
		end
	end

	if preferHighest then
		for _, reagent in ipairs(slot.reagents) do
			if reagent and reagent.itemID and reagent.itemID ~= 0 then return reagent.itemID end
		end
	else
		for index = #slot.reagents, 1, -1 do
			local reagent = slot.reagents[index]
			if reagent and reagent.itemID and reagent.itemID ~= 0 then return reagent.itemID end
		end
	end

	return nil
end

function BuildShoppingList()
	local need = {} -- [itemID] = fehlende Menge
	local multipliers = addon.Vendor.CraftShopper.multipliers or {}

	for _, isRecraft in ipairs(isRecraftTbl) do
		local recipes = C_TradeSkillUI.GetRecipesTracked(isRecraft) or {}
		for _, recipeID in ipairs(recipes) do
			local schem = getSchematic(recipeID, isRecraft)
			local mult = multipliers[recipeID] or 1
			if schem and schem.reagentSlotSchematics then
				for _, slot in ipairs(schem.reagentSlotSchematics) do
					-- Nur Pflicht-Reagenzien mit echter ItemID erfassen.
					if slot.reagentType == Enum.CraftingReagentType.Basic and slot.required then
						local reqQty = slot.quantityRequired * mult
						local id = GetTrackedReagentItemID(slot)
						if id then
							need[id] = need[id] or {}
							need[id].qty = (need[id].qty or 0) + reqQty
							need[id].canAHBuy = isAHBuyable(id)
						end
					end
				end
			end
		end
	end

	local items = {}
	for itemID, want in pairs(need) do
		local owned = C_Item.GetItemCount(itemID, true, false, false, ShouldIncludeWarbandBank()) -- inkl. Bank, optional Warband Bank
		if purchasedItems[itemID] and owned >= want.qty then purchasedItems[itemID] = nil end
		local missing = math.max(want.qty - owned, 0)
		if missing > 0 and not purchasedItems[itemID] then
			table.insert(items, {
				itemID = itemID,
				qtyNeeded = want.qty,
				owned = owned,
				missing = missing,
				ahBuyable = want.canAHBuy,
				hidden = false,
			})
		end
	end
	return items
end

local function CancelPendingAHShowScan()
	if pendingAHShowScan then
		pendingAHShowScan:Cancel()
		pendingAHShowScan = nil
	end
end

local function HideCraftShopperFrame()
	if addon.Vendor.CraftShopper.frame then addon.Vendor.CraftShopper.frame.frame:Hide() end
	f:UnregisterEvent("COMMODITY_PRICE_UPDATED")
	f:UnregisterEvent("COMMODITY_PURCHASE_FAILED")
	f:UnregisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
	f:UnregisterEvent("AUCTION_HOUSE_SHOW_ERROR")
end

local function CanRescanShoppingList()
	if AuctionHouseFrame and AuctionHouseFrame:IsShown() then return true end
	return IsResting and IsResting() or false
end

local function Rescan()
	if scanRunning then return end
	scanRunning = true
	pendingScan = nil
	if not CanRescanShoppingList() then
		scanRunning = false
		return
	end
	addon.Vendor.CraftShopper.items = BuildShoppingList()
	if addon.Vendor.CraftShopper.frame then addon.Vendor.CraftShopper.frame:Refresh() end
	scanRunning = false
	ShowCraftShopperFrameIfNeeded()
end

local function SyncCraftShopperQualityControls()
	local mode = GetCraftShopperReagentQualityMode()
	local frameDropdown = addon.Vendor.CraftShopper.frame and addon.Vendor.CraftShopper.frame.qualityPreference
	if frameDropdown and frameDropdown.GetValue and frameDropdown:GetValue() ~= mode then frameDropdown:SetValue(mode) end
end

function addon.Vendor.CraftShopper.GetReagentQualityMode()
	return GetCraftShopperReagentQualityMode()
end

function addon.Vendor.CraftShopper.RefreshShoppingList()
	SyncCraftShopperQualityControls()
	if not IsCraftShopperEnabled() then return end

	if HasTrackedRecipes() then
		RegisterHeavyEvents()
		Rescan()
	else
		UnregisterHeavyEvents()
		addon.Vendor.CraftShopper.items = {}
		if addon.Vendor.CraftShopper.frame then
			addon.Vendor.CraftShopper.frame:Refresh()
			addon.Vendor.CraftShopper.frame.frame:Hide()
		end
	end

	if RefreshMultiplyUIState then RefreshMultiplyUIState() end
end

function addon.Vendor.CraftShopper.SetReagentQualityMode(mode)
	if not addon.db then return end
	addon.db["vendorCraftShopperReagentQuality"] = mode == CRAFT_SHOPPER_QUALITY_LOWEST and CRAFT_SHOPPER_QUALITY_LOWEST or CRAFT_SHOPPER_QUALITY_HIGHEST
	addon.Vendor.CraftShopper.RefreshShoppingList()
end

function addon.Vendor.CraftShopper.SetIncludeWarbandBank(enabled)
	if not addon.db then return end
	addon.db["vendorCraftShopperIncludeWarbandBank"] = enabled == true
	addon.Vendor.CraftShopper.RefreshShoppingList()
end

local function ScheduleRescan()
	if not CanRescanShoppingList() then return end
	if pendingScan or scanRunning then return end
	pendingScan = C_Timer.NewTimer(SCAN_DELAY, Rescan)
end

local mapQuality = {
	[0] = Enum.AuctionHouseFilter.PoorQuality,
	[1] = Enum.AuctionHouseFilter.CommonQuality,
	[2] = Enum.AuctionHouseFilter.UncommonQuality,
	[3] = Enum.AuctionHouseFilter.RareQuality,
	[4] = Enum.AuctionHouseFilter.EpicQuality,
	[5] = Enum.AuctionHouseFilter.LegendaryQuality,
	[6] = Enum.AuctionHouseFilter.ArtifactQuality,
	[7] = Enum.AuctionHouseFilter.LegendaryCraftedItemOnly,
}

-- Only handle generic Auction House errors relevant to commodity purchases.
local purchaseErrorCodes = {
	[Enum.AuctionHouseError.NotEnoughMoney] = true,
	[Enum.AuctionHouseError.ItemNotFound] = true,
}

-- Shows a small confirmation window for a pending commodity purchase.
-- Displays a spinner and countdown while waiting for the price from the server.
-- When the price is known, the user can confirm or cancel the buy.
local function ShowPurchasePopup(item, buyWidget)
	if pendingPurchase then return end -- do not allow multiple parallel purchases
	buyWidget:SetDisabled(true)

	local popup = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
	popup:SetSize(280, 150)
	popup:SetPoint("TOP", UIParent, "TOP", 0, -200)
	popup:SetFrameStrata("TOOLTIP")
	popup:EnableMouse(true)
	popup:SetMovable(true)
	popup:RegisterForDrag("LeftButton")
	popup:SetScript("OnDragStart", popup.StartMoving)
	popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

	popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	popup.title:SetPoint("CENTER", popup.TitleBg, "CENTER")
	popup.title:SetText(L["vendorCraftShopperConfirmPurchase"])
	popup.title:SetFont(addon.variables.defaultFont, 16, "OUTLINE")

	local text = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOP", 0, -40)
	text:SetJustifyH("CENTER")
	text:SetText(L["vendorCraftShopperWaitingForPrice"])
	text:SetFont(addon.variables.defaultFont, 14, "OUTLINE")
	popup.text = text

	local timerLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	timerLabel:SetPoint("TOP", text, "BOTTOM", 0, -10)
	timerLabel:SetJustifyH("CENTER")
	timerLabel:SetFont(addon.variables.defaultFont, 14, "OUTLINE")
	popup.timerLabel = timerLabel

	local buyBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	buyBtn:SetSize(120, 24)
	buyBtn:SetPoint("BOTTOMLEFT", 10, 10)
	buyBtn:SetText(L["vendorCraftShopperBuyNow"])
	buyBtn:Disable()
	popup.buyBtn = buyBtn

	local cancelBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	cancelBtn:SetSize(120, 24)
	cancelBtn:SetPoint("BOTTOMRIGHT", -10, 10)
	cancelBtn:SetText(L["vendorCraftShopperCancel"])
	popup.cancelBtn = cancelBtn

	popup.CloseButton:SetScript("OnClick", function() cancelBtn:Click() end)

	local spinner = CreateFrame("Frame", nil, popup, "LoadingSpinnerTemplate")
	spinner:SetPoint("TOP", 0, -25)
	spinner:SetSize(24, 24)
	spinner:Show()
	popup.spinner = spinner

	popup.remaining = 15
	timerLabel:SetText(L["vendorCraftShopperTimeRemaining"]:format(popup.remaining))
	popup.ticker = C_Timer.NewTicker(1, function()
		popup.remaining = popup.remaining - 1
		if popup.remaining <= 0 then
			cancelBtn:Click()
		else
			timerLabel:SetText(L["vendorCraftShopperTimeRemaining"]:format(popup.remaining))
		end
	end)

	buyBtn:SetScript("OnClick", function()
		f:RegisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
		lastPurchaseItemID = item.itemID
		C_AuctionHouse.ConfirmCommoditiesPurchase(item.itemID, item.missing)
		if popup.ticker then popup.ticker:Cancel() end
		popup:Hide()
		pendingPurchase = nil
		buyWidget:SetDisabled(false)
	end)

	cancelBtn:SetScript("OnClick", function()
		C_AuctionHouse.CancelCommoditiesPurchase(item.itemID)
		if popup.ticker then popup.ticker:Cancel() end
		popup:Hide()
		f:UnregisterEvent("COMMODITY_PRICE_UPDATED")
		f:UnregisterEvent("COMMODITY_PURCHASE_FAILED")
		f:UnregisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
		f:UnregisterEvent("AUCTION_HOUSE_SHOW_ERROR")
		pendingPurchase = nil
		buyWidget:SetDisabled(false)
	end)

	pendingPurchase = {
		item = item,
		popup = popup,
		buyWidget = buyWidget,
	}
end

local function UpdatePurchasePopup(pricePer, total)
	if not pendingPurchase then return end
	f:UnregisterEvent("COMMODITY_PRICE_UPDATED")

	if pendingPurchase.popup.spinner then pendingPurchase.popup.spinner:Hide() end

	local playerMoney = GetMoney()
	if playerMoney < total then
		pendingPurchase.popup.text:SetText(L["vendorCraftShopperMissingGold"]:format(GetMoneyString(total - playerMoney)))
		pendingPurchase.popup.buyBtn:Hide()
		pendingPurchase.popup.cancelBtn:SetText(CLOSE)
		pendingPurchase.popup.cancelBtn:ClearAllPoints()
		pendingPurchase.popup.cancelBtn:SetPoint("BOTTOM", 0, 10)
	else
		pendingPurchase.popup.text:SetText(("%s x%d\n%s"):format(pendingPurchase.item.name, pendingPurchase.item.missing, GetMoneyString(total)))
		pendingPurchase.popup.buyBtn:Show()
		pendingPurchase.popup.buyBtn:Enable()
		pendingPurchase.popup.buyBtn:ClearAllPoints()
		pendingPurchase.popup.buyBtn:SetPoint("BOTTOMLEFT", 10, 10)
		pendingPurchase.popup.cancelBtn:SetText(L["vendorCraftShopperCancel"])
		pendingPurchase.popup.cancelBtn:ClearAllPoints()
		pendingPurchase.popup.cancelBtn:SetPoint("BOTTOMRIGHT", -10, 10)
	end
end

local function SetCheckButtonValue(button, value)
	if button and button.SetChecked then button:SetChecked(value == true) end
end

local function GetCheckButtonValue(button)
	return button and button.GetChecked and button:GetChecked() == true or false
end

local function CreateCraftShopperCheckButton(parent, label)
	local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	button.Text:SetText(label or "")
	button.SetValue = SetCheckButtonValue
	button.GetValue = GetCheckButtonValue
	return button
end

local function SetNativeButtonDisabled(button, disabled)
	if disabled then
		button:Disable()
		if button.icon then button.icon:SetDesaturated(true) end
		button:SetAlpha(0.45)
	else
		button:Enable()
		if button.icon then button.icon:SetDesaturated(false) end
		button:SetAlpha(1)
	end
end

local function CreateCraftShopperIconButton(parent, texture, tooltipText, onClick)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(20, 20)
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetAllPoints()
	button.icon:SetTexture(texture)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(tooltipText)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnClick", onClick)
	button.SetDisabled = SetNativeButtonDisabled
	return button
end

local function SetQualityButtonValue(button, mode)
	local value = mode == CRAFT_SHOPPER_QUALITY_LOWEST and CRAFT_SHOPPER_QUALITY_LOWEST or CRAFT_SHOPPER_QUALITY_HIGHEST
	button.value = value
	button:SetText(craftShopperQualityList[value] or value)
end

local function GetQualityButtonValue(button)
	return button.value or GetCraftShopperReagentQualityMode()
end

local function OpenQualityMenu(button)
	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(button, function(_, rootDescription)
			for _, mode in ipairs(craftShopperQualityOrder) do
				rootDescription:CreateRadio(craftShopperQualityList[mode] or mode, function() return GetCraftShopperReagentQualityMode() == mode end, function()
					if addon.Vendor and addon.Vendor.CraftShopper and addon.Vendor.CraftShopper.SetReagentQualityMode then
						addon.Vendor.CraftShopper.SetReagentQualityMode(mode)
					end
				end)
			end
		end)
	else
		local nextMode = GetCraftShopperReagentQualityMode() == CRAFT_SHOPPER_QUALITY_LOWEST and CRAFT_SHOPPER_QUALITY_HIGHEST or CRAFT_SHOPPER_QUALITY_LOWEST
		if addon.Vendor and addon.Vendor.CraftShopper and addon.Vendor.CraftShopper.SetReagentQualityMode then
			addon.Vendor.CraftShopper.SetReagentQualityMode(nextMode)
		end
	end
end

local function AnchorFrameToCurrentScreenPosition(frame)
	if not frame or not UIParent or not frame.GetLeft or not frame.GetTop then return end
	local left = frame:GetLeft()
	local top = frame:GetTop()
	if not left or not top then return end

	local frameScale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
	local parentScale = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
	if frameScale <= 0 then frameScale = 1 end
	if parentScale <= 0 then parentScale = 1 end

	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * frameScale / parentScale, top * frameScale / parentScale)
end

local function CreateCraftShopperFrame()
	if addon.Vendor.CraftShopper.frame then return addon.Vendor.CraftShopper.frame end
	local frame = CreateFrame("Frame", "EnhanceQoLCraftShopperFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(300, 400)
	frame:Hide()
	frame.frame = frame
	frame.rows = {}
	frame:SetFrameStrata(AuctionHouseFrame:GetFrameStrata())
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(300, 240, nil, nil)
	elseif frame.SetMinResize then
		frame:SetMinResize(300, 240)
	end
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		AnchorFrameToCurrentScreenPosition(self)
		self.userMoved = true
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame.TitleText:SetText(L["vendorCraftShopperTitle"])

	local resizeButton = CreateFrame("Button", nil, frame)
	resizeButton:SetSize(16, 16)
	resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
	resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	resizeButton:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return end
		self:SetButtonState("PUSHED", true)
		if self:GetHighlightTexture() then self:GetHighlightTexture():Hide() end
		AnchorFrameToCurrentScreenPosition(frame)
		frame:StartSizing("BOTTOMRIGHT")
	end)
	resizeButton:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then return end
		self:SetButtonState("NORMAL")
		if self:GetHighlightTexture() then self:GetHighlightTexture():Show() end
		frame:StopMovingOrSizing()
		frame.userSized = true
		frame:Refresh()
	end)
	frame.ResizeButton = resizeButton

	local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	searchLabel:SetPoint("TOPLEFT", 12, -30)
	searchLabel:SetText(SEARCH)

	local search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	search:SetAutoFocus(false)
	search:SetHeight(22)
	search:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -46)
	search:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -46)
	search:SetScript("OnTextChanged", function() frame:Refresh() end)
	frame.search = search

	local ahCheck = CreateCraftShopperCheckButton(frame, L["vendorCraftShopperAHBuyable"])
	ahCheck:SetPoint("TOPLEFT", search, "BOTTOMLEFT", -6, -6)
	ahCheck:SetScript("OnClick", function() frame:Refresh() end)
	frame.ahBuyable = ahCheck

	local qualityLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	qualityLabel:SetPoint("TOPLEFT", ahCheck, "BOTTOMLEFT", 6, -4)
	qualityLabel:SetText(L["vendorCraftShopperReagentQuality"])

	local qualityPreference = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	qualityPreference:SetHeight(22)
	qualityPreference:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -111)
	qualityPreference:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -111)
	qualityPreference:SetScript("OnClick", OpenQualityMenu)
	qualityPreference.SetValue = SetQualityButtonValue
	qualityPreference.GetValue = GetQualityButtonValue
	qualityPreference:SetValue(GetCraftShopperReagentQualityMode())
	frame.qualityPreference = qualityPreference

	local header = CreateFrame("Frame", nil, frame)
	header:SetPoint("TOPLEFT", qualityPreference, "BOTTOMLEFT", 0, -8)
	header:SetPoint("TOPRIGHT", qualityPreference, "BOTTOMRIGHT", 0, -8)
	header:SetHeight(22)
	frame.header = header

	header.item = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	header.item:SetPoint("LEFT")
	header.item:SetText(AUCTION_HOUSE_HEADER_ITEM)
	header.item:SetJustifyH("LEFT")

	header.need = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	header.need:SetText(NEED)
	header.need:SetJustifyH("LEFT")

	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
	scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 28)
	frame.scroll = scroll

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	frame.content = content

	function frame:Refresh()
		local normalFont, _, normalFlags = GameFontNormal:GetFont()
		local searchText = (search:GetText() or ""):lower()
		local rowWidth = math.max(260, scroll:GetWidth() - 4)
		local itemWidth = math.floor(rowWidth * 0.45)
		local needWidth = math.floor(rowWidth * 0.25)
		local iconGap = 10
		local iconSize = 20
		local rowHeight = 32
		local rowIndex = 0

		header.item:SetWidth(itemWidth)
		header.need:ClearAllPoints()
		header.need:SetPoint("LEFT", header, "LEFT", itemWidth + 4, 0)
		header.need:SetWidth(needWidth)

		for _, row in ipairs(frame.rows) do
			row:Hide()
		end

		for _, item in ipairs(addon.Vendor.CraftShopper.items) do
			if not item.hidden and (not ahCheck:GetValue() or item.ahBuyable) then
				local name, _, quality = C_Item.GetItemInfo(item.itemID)
				name = name or ("item:" .. item.itemID)
				item.name = name
				if searchText == "" or name:lower():find(searchText, 1, true) then
					rowIndex = rowIndex + 1
					local row = frame.rows[rowIndex]
					if not row then
						row = CreateFrame("Frame", nil, content)
						row:SetHeight(rowHeight)

						row.itemButton = CreateFrame("Button", nil, row)
						row.itemButton:SetPoint("LEFT")
						if row.itemButton.SetClipsChildren then row.itemButton:SetClipsChildren(true) end
						row.itemButton.text = row.itemButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						row.itemButton.text:SetPoint("LEFT")
						row.itemButton.text:SetPoint("RIGHT")
						row.itemButton.text:SetJustifyH("LEFT")
						row.itemButton.text:SetWordWrap(false)
						if row.itemButton.text.SetMaxLines then row.itemButton.text:SetMaxLines(1) end
						row.itemButton:SetScript("OnEnter", function(self)
							GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
							GameTooltip:SetItemByID(self.item.itemID)
							GameTooltip:Show()
						end)
						row.itemButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

						row.qty = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						row.qty:SetJustifyH("LEFT")

						row.searchBtn = CreateCraftShopperIconButton(row, ICON_PATH .. "search.tga", L["vendorCraftShopperSearchAH"], function(self)
							local rowItem = self.item
							local itemName, _, rowQuality, _, _, _, _, _, itemEquipLoc, _, _, classID, subclassID = C_Item.GetItemInfo(rowItem.itemID)
							local qualityFilter = { Enum.AuctionHouseFilter.ExactMatch }
							local mappedQuality = mapQuality[rowQuality]
							if mappedQuality then table.insert(qualityFilter, 1, mappedQuality) end
							if not itemName then return end
							local query = {
								searchString = itemName,
								sorts = {
									{ sortOrder = Enum.AuctionHouseSortOrder.Name, reverseSort = false },
									{ sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false },
								},
								filters = qualityFilter,
								itemClassFilters = {
									classID = classID,
									subClassID = subclassID,
									inventoryType = itemEquipLoc,
								},
							}
							C_AuctionHouse.SendBrowseQuery(query)
							AuctionHouseFrame:Show()
							AuctionHouseFrame:Raise()
						end)

						row.buyBtn = CreateCraftShopperIconButton(row, ICON_PATH .. "buy.tga", L["vendorCraftShopperBuyItems"], function(self)
							if pendingPurchase then return end
							f:RegisterEvent("COMMODITY_PRICE_UPDATED")
							f:RegisterEvent("COMMODITY_PURCHASE_FAILED")
							f:RegisterEvent("AUCTION_HOUSE_SHOW_ERROR")
							ShowPurchasePopup(self.item, self)
							C_AuctionHouse.StartCommoditiesPurchase(self.item.itemID, self.item.missing)
						end)

						row.removeBtn = CreateCraftShopperIconButton(row, ICON_PATH .. "delete.tga", L["vendorCraftShopperHideFromList"], function(self)
							self.item.hidden = true
							frame:Refresh()
						end)

						frame.rows[rowIndex] = row
					end

					row:SetParent(content)
					row:ClearAllPoints()
					row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * rowHeight))
					row:SetWidth(rowWidth)
					row.item = item
					row.itemButton.item = item
					row.searchBtn.item = item
					row.buyBtn.item = item
					row.removeBtn.item = item

					row.itemButton:SetSize(itemWidth, rowHeight)
					row.itemButton.text:SetFont(normalFont, 14, normalFlags)
					local color = select(4, C_Item.GetItemQualityColor(quality or 1))
					row.itemButton.text:SetText(("|c%s%s|r"):format(color, name))

					row.qty:ClearAllPoints()
					row.qty:SetPoint("LEFT", row, "LEFT", itemWidth + 4, 0)
					row.qty:SetWidth(needWidth)
					row.qty:SetFont(normalFont, 14, normalFlags)
					row.qty:SetText(("%d"):format(item.missing))

					local iconStart = itemWidth + needWidth + 8
					row.searchBtn:ClearAllPoints()
					row.searchBtn:SetPoint("LEFT", row, "LEFT", iconStart, 0)
					row.buyBtn:ClearAllPoints()
					row.buyBtn:SetPoint("LEFT", row.searchBtn, "RIGHT", iconGap, 0)
					row.removeBtn:ClearAllPoints()
					row.removeBtn:SetPoint("LEFT", row.buyBtn, "RIGHT", iconGap, 0)
					row.searchBtn:SetSize(iconSize, iconSize)
					row.buyBtn:SetSize(iconSize, iconSize)
					row.removeBtn:SetSize(iconSize, iconSize)
					row:Show()
				end
			end
		end

		content:SetSize(rowWidth, math.max(1, rowIndex * rowHeight))
	end

	addon.Vendor.CraftShopper.frame = frame
	frame:SetScript("OnSizeChanged", function(self)
		if self:IsShown() then self:Refresh() end
	end)
	return frame
end

function ShowCraftShopperFrameIfNeeded()
	if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then return end

	local hasItems = false
	for _, item in ipairs(addon.Vendor.CraftShopper.items) do
		if item.ahBuyable and item.missing > 0 then
			hasItems = true
			break
		end
	end

	if hasItems then
		local ui = CreateCraftShopperFrame()
		SyncCraftShopperQualityControls()
		if not ui.frame.userMoved and not ui.frame.userSized then
			ui.frame:ClearAllPoints()
			ui.frame:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPRIGHT", 5, 0)
			local width = math.max(300, AuctionHouseFrame:GetWidth() * 0.4)
			local height = math.max(240, AuctionHouseFrame:GetHeight())
			ui.frame:SetSize(width, height)
		end
		ui.ahBuyable:SetValue(true)
		ui.frame:Show()
		ui:Refresh()
	else
		HideCraftShopperFrame()
	end
end

function addon.Vendor.CraftShopper.EnableCraftShopper()
	f:RegisterEvent("TRACKED_RECIPE_UPDATE")
	EnsureCraftShopperProfessionsUI()
	if HasTrackedRecipes() then
		RegisterHeavyEvents()
		Rescan()
	else
		UnregisterHeavyEvents()
	end
	if RefreshMultiplyUIState then RefreshMultiplyUIState() end
end

function addon.Vendor.CraftShopper.DisableCraftShopper()
	f:UnregisterEvent("TRACKED_RECIPE_UPDATE")
	f:UnregisterEvent("ADDON_LOADED")
	UnregisterHeavyEvents()
	CancelPendingAHShowScan()
	if pendingScan then
		pendingScan:Cancel()
		pendingScan = nil
	end
	if addon.Vendor.CraftShopper.frame then addon.Vendor.CraftShopper.frame.frame:Hide() end
	if _G.EQOLCrafterMultiply then _G.EQOLCrafterMultiply:Hide() end
	local checkbox = GetTrackRecipeCheckbox()
	if checkbox and checkbox.SetAlpha then checkbox:SetAlpha(1) end
end

local function initializeCraftShopper()
	if addon.db["vendorCraftShopperEnable"] then addon.Vendor.CraftShopper.EnableCraftShopper() end
end
if IsLoggedIn and IsLoggedIn() then
	initializeCraftShopper()
else
	f:RegisterEvent("PLAYER_LOGIN")
end

local function addToCraftShopper(el)
	if not el or not el.GetText then return end
	local txt = el:GetText()
	local count = tonumber(txt)
	if count == nil then
		el:SetText("")
		return
	end

	-- Determine current recipeID from the professions UI
	local recipeID
	if
		ProfessionsFrame
		and ProfessionsFrame.CraftingPage
		and ProfessionsFrame.CraftingPage.SchematicForm
		and ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo
		and ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID
	then
		recipeID = ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID
	end

	if not recipeID then return end

	count = math.floor(count)
	if count <= 0 then
		-- 0 => löschen: Multiplikator entfernen und Rezept untracken
		addon.Vendor.CraftShopper.multipliers[recipeID] = nil
		if C_TradeSkillUI and C_TradeSkillUI.SetRecipeTracked then pcall(C_TradeSkillUI.SetRecipeTracked, recipeID, false, false) end
		el:SetText("")
	else
		-- Store multiplier and ensure recipe is tracked
		addon.Vendor.CraftShopper.multipliers[recipeID] = count
		if C_TradeSkillUI and C_TradeSkillUI.SetRecipeTracked then pcall(C_TradeSkillUI.SetRecipeTracked, recipeID, true, false) end
		el:SetText("")
	end

	-- Update list immediately and show the UI
	addon.Vendor.CraftShopper.items = BuildShoppingList()
	if addon.Vendor.CraftShopper.frame then addon.Vendor.CraftShopper.frame:Refresh() end
	ShowCraftShopperFrameIfNeeded()
end

createCrafterMultiplyFrame = function()
	local schematicForm = ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
	if not schematicForm then return nil end
	if _G.EQOLCrafterMultiply then return _G.EQOLCrafterMultiply end

	local fCMF = CreateFrame("frame", "EQOLCrafterMultiply", schematicForm, "BackdropTemplate")
	-- Compact, unobtrusive container in the top-right of the schematic form

	-- local parent = ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckbox
	local parent = fCMF
	-- fCMF:SetPoint("RIGHT", ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckbox, "LEFT", -5)
	fCMF:SetPoint("TOPRIGHT", schematicForm, "TOPRIGHT", -5)
	fCMF:SetSize(260, 32)
	fCMF:SetFrameStrata("HIGH")
	fCMF:EnableMouse(true)
	fCMF.autoFilled = false

	-- Visible, skinned OK button
	local btnOK = CreateFrame("Button", nil, fCMF, "UIPanelButtonTemplate")
	local eb = CreateFrame("EditBox", nil, fCMF, "InputBoxTemplate")
	local label = fCMF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

	fCMF.ok = btnOK
	btnOK:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -3, -2)
	btnOK:SetSize(70, 22)
	btnOK:SetText(TRACK_ACHIEVEMENT)
	btnOK:SetScript("OnClick", function()
		if btnOK:GetText() == PROFESSIONS_UNTRACK_RECIPE then
			fCMF.autoFilled = false
			eb:SetText("0")
			addToCraftShopper(eb)
			eb:ClearFocus()
			if RefreshMultiplyUIState then RefreshMultiplyUIState() end
			return
		end
		if eb and eb.GetText then
			if nil == eb:GetText() or eb:GetText() == "" then
				fCMF.autoFilled = true
				eb:SetText("1")
			end
		end
		addToCraftShopper(eb)
		eb:ClearFocus()
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	end)

	-- Label + edit box for quantity
	label:SetPoint("RIGHT", eb, "LEFT", -6, 0)
	label:SetText(L["vendorCraftShopperTrackQuantity"])

	fCMF.editBox = eb
	eb:SetPoint("RIGHT", btnOK, "LEFT", -3, 0)
	eb:SetAutoFocus(false)
	eb:SetHeight(22)
	eb:SetWidth(60)
	eb:SetFontObject(ChatFontNormal)
	eb:SetMaxLetters(5)

	eb:SetScript("OnEnterPressed", function(self)
		if (self:GetText() or "") == "" then
			if self:GetParent() then self:GetParent().autoFilled = true end
			self:SetText("1")
		end
		addToCraftShopper(self)
		self:ClearFocus()
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	end)
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	eb:SetScript("OnTextChanged", function(self, userInput)
		if userInput and self:GetParent() then self:GetParent().autoFilled = false end
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	end)

	-- Ensure sub-widgets are visible (frame visibility controlled below)
	eb:Show()
	btnOK:Show()

	-- Track recipe changes to refresh button label
	fCMF._accum = 0
	fCMF.lastRecipeID = nil
	local function updateRecipeWatcher(self, elapsed)
		self._accum = (self._accum or 0) + elapsed
		if self._accum < 0.3 then return end
		self._accum = 0
		local rid
		if GetCurrentRecipeID then rid = GetCurrentRecipeID() end
		if rid ~= self.lastRecipeID then
			self.lastRecipeID = rid
			self.autoFilled = false
			if self.editBox and self.editBox:GetText() ~= "" then self.editBox:SetText("") end
			if UpdateMultiplyFrameState then UpdateMultiplyFrameState() end
		end
	end
	fCMF:SetScript("OnShow", function(self)
		self._accum = 0
		self:SetScript("OnUpdate", updateRecipeWatcher)
	end)
	fCMF:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)

	-- Default hidden; only show when enabled and professions is visible
	fCMF:Hide()
	if RefreshMultiplyUIState then RefreshMultiplyUIState() end

	return fCMF
end

f:SetScript("OnEvent", function(_, event, arg1, arg2)
	if event == "PLAYER_LOGIN" then
		initializeCraftShopper()
	elseif event == "ADDON_LOADED" and arg1 == "Blizzard_Professions" then
		if IsCraftShopperEnabled() then EnsureCraftShopperProfessionsUI() end
		-- No longer need to listen for further ADDON_LOADED
		f:UnregisterEvent("ADDON_LOADED")
	elseif event == "TRADE_SKILL_SHOW" then
		if IsCraftShopperEnabled() then EnsureCraftShopperProfessionsUI() end
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	elseif event == "TRADE_SKILL_CLOSE" then
		if _G.EQOLCrafterMultiply then _G.EQOLCrafterMultiply:Hide() end
		local checkbox = GetTrackRecipeCheckbox()
		if checkbox and checkbox.SetAlpha and IsCraftShopperEnabled() then checkbox:SetAlpha(1) end
	elseif event == "TRACKED_RECIPE_UPDATE" then
		CleanupUntrackedMultipliers()
		if HasTrackedRecipes() then
			RegisterHeavyEvents()
			ScheduleRescan()
		else
			UnregisterHeavyEvents()
			if pendingScan then
				pendingScan:Cancel()
				pendingScan = nil
			end
			if addon.Vendor.CraftShopper.frame then addon.Vendor.CraftShopper.frame.frame:Hide() end
		end
		if RefreshMultiplyUIState then RefreshMultiplyUIState() end
	elseif event == "BAG_UPDATE_DELAYED" then
		ScheduleRescan()
	elseif event == "CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE" then
		if arg1 == 0 and not scanRunning then Rescan() end
	elseif event == "AUCTION_HOUSE_SHOW" then
		Rescan()
		CancelPendingAHShowScan()
		-- AH open can race recipe tracking data settling; retry once shortly after show.
		pendingAHShowScan = C_Timer.NewTimer(SCAN_DELAY, function()
			pendingAHShowScan = nil
			Rescan()
		end)
	elseif event == "AUCTION_HOUSE_CLOSED" then
		CancelPendingAHShowScan()
		HideCraftShopperFrame()
	elseif event == "COMMODITY_PRICE_UPDATED" then
		UpdatePurchasePopup(arg1, arg2)
	elseif event == "COMMODITY_PURCHASE_FAILED" or (event == "AUCTION_HOUSE_SHOW_ERROR" and purchaseErrorCodes[arg1]) then
		lastPurchaseItemID = nil
		if pendingPurchase then
			f:UnregisterEvent("COMMODITY_PRICE_UPDATED")
			f:UnregisterEvent("COMMODITY_PURCHASE_FAILED")
			f:UnregisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
			f:UnregisterEvent("AUCTION_HOUSE_SHOW_ERROR")
			if pendingPurchase.popup.ticker then pendingPurchase.popup.ticker:Cancel() end
			if pendingPurchase.popup.spinner then pendingPurchase.popup.spinner:Hide() end
			pendingPurchase.popup.text:SetText(L["vendorCraftShopperPurchaseFailed"])
			pendingPurchase.popup.timerLabel:SetText("")
			pendingPurchase.popup.buyBtn:Hide()
			pendingPurchase.popup.cancelBtn:SetText(OKAY)
			pendingPurchase.popup.cancelBtn:ClearAllPoints()
			pendingPurchase.popup.cancelBtn:SetPoint("BOTTOM", 0, 10)
			pendingPurchase.buyWidget:SetDisabled(false)
		end
	elseif event == "COMMODITY_PURCHASE_SUCCEEDED" then
		f:UnregisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
		f:UnregisterEvent("AUCTION_HOUSE_SHOW_ERROR")
		f:UnregisterEvent("COMMODITY_PURCHASE_FAILED")
		local itemID = lastPurchaseItemID
		lastPurchaseItemID = nil
		if itemID then
			for _, item in ipairs(addon.Vendor.CraftShopper.items) do
				if item.itemID == itemID then
					item.hidden = true
					break
				end
			end
			purchasedItems[itemID] = true
			if addon.Vendor.CraftShopper.frame then addon.Vendor.CraftShopper.frame:Refresh() end
		end
		ScheduleRescan()
	else
		Rescan()
	end
end)

function addon.Vendor.functions.checkList()
	Rescan()
	for _, item in ipairs(addon.Vendor.CraftShopper.items) do
		if item.ahBuyable then
			local info = C_Item.GetItemInfo(item.itemID)
			print(L["vendorCraftShopperCheckListPrint"]:format(info or ("ItemID " .. item.itemID), item.missing))
		end
	end
end
