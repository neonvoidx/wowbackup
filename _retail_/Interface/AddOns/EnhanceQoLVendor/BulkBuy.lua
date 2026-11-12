local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local B = {}
addon.Vendor.BulkBuy = B
B.events = CreateFrame("Frame")

function B:Enabled() return addon.db and addon.db.vendorBulkBuy == true end

function B:ItemCount(link, bank)
	return C_Item.GetItemCount(link, bank or false, false, false)
end

-- Link level, specialization, display name and unique instance IDs do not change stackability.
function B:StackKey(link)
	local item = link and link:match("item:([^|]+)")
	if not item then return end
	local fields = {}
	for value in (item .. ":"):gmatch("(.-):") do fields[#fields + 1] = value ~= "" and value or "0" end
	for _, index in ipairs({ 8, 9, 10 }) do if fields[index] then fields[index] = "0" end end
	while fields[#fields] == "0" do fields[#fields] = nil end
	return table.concat(fields, ":")
end

-- Count only bags that can accept this item; occupied partial stacks remain usable.
function B:Capacity(link, stack)
	local capacity = 0
	local stackKey = self:StackKey(link)
	local family = C_Item.GetItemFamily(link) or 0
	local lastBag = addon.variables.isTBC and (NUM_BAG_SLOTS or 4) or (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4)
	for bag = 0, lastBag do
		local free, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
		if free and (bagFamily == 0 or (family ~= 0 and bit.band(family, bagFamily or 0) ~= 0)) then
			capacity = capacity + free * stack
		end
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			-- Preserve variant fields; item IDs alone do not establish stackability.
			if info and not info.isLocked and self:StackKey(info.hyperlink) == stackKey then capacity = capacity + math.max(0, stack - info.stackCount) end
		end
	end
	return capacity
end

function B:Read(index)
	if not self:Enabled() or not MerchantFrame or not MerchantFrame:IsShown() or MerchantFrame.selectedTab ~= 1 then return end
	local link = GetMerchantItemLink(index)
	if not link then return end
	local info
	if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
		info = C_MerchantFrame.GetItemInfo(index)
	else
		local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, hasExtendedCost = GetMerchantItemInfo(index)
		info = { name = name, texture = texture, price = price, stackCount = stackCount, numAvailable = numAvailable, isPurchasable = isPurchasable, isUsable = isUsable, hasExtendedCost = hasExtendedCost }
	end
	if not info or not info.name or not info.stackCount or info.stackCount < 1 then return end
	local stack = select(8, C_Item.GetItemInfo(link))
	if not stack or stack < 1 then return end -- Item data must be cached before offering a quantity.
	local data = {
		index = index, link = link, merchant = UnitGUID("npc"), bundle = info.stackCount,
		stack = stack, price = info.price or 0, costs = {},
		chunk = GetMerchantItemMaxStack(index),
	}
	if not data.merchant or not data.chunk or data.chunk < data.bundle then return end
	local limit = self:Capacity(link, stack)
	if info.isPurchasable == false then limit = 0 end
	if info.numAvailable and info.numAvailable >= 0 then limit = math.min(limit, info.numAvailable) end
	if data.price > 0 then limit = math.min(limit, math.floor(GetMoney() / data.price) * data.bundle) end
	local signatures = { link, tostring(data.price), tostring(data.bundle) }
	if info.hasExtendedCost then
		for costIndex = 1, GetMerchantItemCostInfo(index) do
			local texture, amount, costLink, currencyName = GetMerchantItemCostItem(index, costIndex)
			if not amount or amount <= 0 or not costLink then return end
			local currencyID = tonumber(costLink:match("currency:(%d+)"))
			local owned
			if currencyID then
				local currency = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
				if not currency then return end
				owned = currency.quantity
			elseif costLink:find("item:", 1, true) then
				owned = self:ItemCount(costLink)
			else
				return -- Unknown cost types must never produce an unlimited MAX.
			end
			limit = math.min(limit, math.floor(owned / amount) * data.bundle)
			data.costs[#data.costs + 1] = { texture = texture, amount = amount, link = costLink, name = currencyName }
			signatures[#signatures + 1] = costLink .. ":" .. amount
		end
		if #data.costs == 0 then return end
	end
	if C_Item.GetItemUniquenessByID then
		local unique, _, count = C_Item.GetItemUniquenessByID(link)
		if unique then limit = math.min(limit, math.max(0, (count or 1) - self:ItemCount(link, true))) end
	end
	data.limit = math.max(0, math.floor(limit / data.bundle) * data.bundle)
	data.chunk = math.floor(data.chunk / data.bundle) * data.bundle
	data.signature = table.concat(signatures, "\n")
	return data
end

function B:SameOffer(a, b)
	return a and b and a.merchant == b.merchant and a.index == b.index and a.signature == b.signature
end

function B:CostText(data, quantity)
	local costs = {}
	local bundles = quantity / data.bundle
	if data.price > 0 then costs[#costs + 1] = GetMoneyString(data.price * bundles) end
	for _, cost in ipairs(data.costs) do
		costs[#costs + 1] = string.format("%d |T%s:14|t %s", cost.amount * bundles, cost.texture, cost.name or cost.link)
	end
	return #costs > 0 and table.concat(costs, "\n") or _G.FREE
end

function B:DialogParts()
	local frame = self.frame
	return {
		text = frame.StackSplitText or _G.StackSplitText,
		count = frame.StackItemCountText,
		left = frame.LeftButton or _G.StackSplitLeftButton,
		right = frame.RightButton or _G.StackSplitRightButton,
		okay = frame.OkayButton or _G.StackSplitOkayButton,
		cancel = frame.CancelButton or _G.StackSplitCancelButton,
	}
end

function B:RestoreLayout()
	local layout = self.layout
	if not layout then return end
	self.layout = nil
	self.frame:SetSize(layout.width, layout.height)
	for _, record in ipairs(layout.regions) do
		record.region:ClearAllPoints()
		for _, point in ipairs(record.points) do record.region:SetPoint(unpack(point)) end
		if record.width then record.region:SetSize(record.width, record.height) end
	end
end

function B:LayoutDialog()
	self:RestoreLayout()
	local frame = self.frame
	local parts = self:DialogParts()
	local width, height = frame:GetSize()
	local layout = { width = width, height = height, regions = {} }
	local function remember(region, size)
		if not region then return end
		local record = { region = region, points = {} }
		for i = 1, region:GetNumPoints() do record.points[i] = { region:GetPoint(i) } end
		if size then record.width, record.height = region:GetSize() end
		layout.regions[#layout.regions + 1] = record
	end
	for _, region in pairs(parts) do remember(region) end
	-- Keep Blizzard's original artwork, stretched vertically to enclose the extra row.
	local backgrounds = { frame.SingleItemSplitBackground, frame.MultiItemSplitBackground }
	if not backgrounds[1] then
		backgrounds = {}
		for _, region in ipairs({ frame:GetRegions() }) do
			if region:GetObjectType() == "Texture" then backgrounds[#backgrounds + 1] = region end
		end
	end
	for _, background in ipairs(backgrounds) do remember(background, true); background:ClearAllPoints(); background:SetAllPoints(frame) end
	self.layout = layout
	local multi = frame.isMultiStack == true
	frame:SetSize(width, height + 36)
	local function place(region, point, relative, x, y)
		if region then region:ClearAllPoints(); region:SetPoint(point, frame, relative, x, y) end
	end
	if multi then place(parts.text, "CENTER", "TOP", 5, -41) else place(parts.text, "RIGHT", "TOPRIGHT", -50, -41) end
	place(parts.left, "RIGHT", "TOPLEFT", 27, -41)
	place(parts.right, "LEFT", "TOPLEFT", 150, -41)
	if multi then place(parts.count, "CENTER", "TOP", 0, -65) end
	local row = multi and -88 or -64
	place(self.stack, "TOPRIGHT", "TOP", -3, row)
	place(self.maximum, "TOPLEFT", "TOP", 5, row)
	place(parts.okay, "TOPRIGHT", "TOP", -3, row - 24)
	place(parts.cancel, "TOPLEFT", "TOP", 5, row - 24)
end

function B:UpdateProgress()
	local order = self.order
	if not order or not self.progress then return end
	self.progress.bar:SetMinMaxValues(0, order.total)
	self.progress.bar:SetValue(order.total - order.remaining)
	self.progress.text:SetText(string.format(L["vendorBulkBuyProgress"], order.total - order.remaining, order.total, order.remaining))
end

function B:ShowProgress()
	if not self.progress then
		local frame = CreateFrame("Frame", "EQOLVendorPurchaseProgress", UIParent)
		self.progress = frame
		frame:Hide()
		frame:SetSize(220, 112)
		frame:SetFrameStrata("DIALOG")
		frame:SetClampedToScreen(true)
		frame:EnableMouse(true)
		-- Reuse the neutral border/body of the native artwork without its quantity field.
		local function backgroundSlice(top, bottom, y, height)
			local texture = frame:CreateTexture(nil, "BACKGROUND")
			texture:SetTexture("Interface\\MoneyFrame\\UI-MoneyFrame")
			texture:SetTexCoord(0, 0.671875, top, bottom)
			texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
			texture:SetSize(220, height)
		end
		backgroundSlice(0, 0.09375, 0, 12)
		backgroundSlice(0.46875, 0.65625, -12, 88)
		backgroundSlice(0.65625, 0.75, -100, 12)
		frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		frame.text:SetPoint("TOP", 0, -15)
		frame.text:SetWidth(192)
		frame.bar = CreateFrame("StatusBar", nil, frame)
		frame.bar:SetSize(174, 16)
		frame.bar:SetPoint("TOP", 0, -47)
		frame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		frame.bar:SetStatusBarColor(0.9, 0.7, 0.1)
		local border = frame.bar:CreateTexture(nil, "OVERLAY")
		border:SetTexture("Interface\\Tooltips\\UI-StatusBar-Border")
		border:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", -2, 2)
		border:SetPoint("BOTTOMRIGHT", frame.bar, "BOTTOMRIGHT", 2, -2)
		local empty = frame.bar:CreateTexture(nil, "BACKGROUND")
		empty:SetAllPoints(frame.bar)
		empty:SetColorTexture(0.12, 0.1, 0.05, 1)
		frame.cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		frame.cancel:SetSize(100, 24)
		frame.cancel:SetPoint("BOTTOM", 0, 18)
		frame.cancel:SetText(CANCEL)
		frame.cancel:SetScript("OnClick", function() B:Stop() end)
		frame:SetScript("OnHide", function() if B.order then B:Stop() end end)
		table.insert(UISpecialFrames, "EQOLVendorPurchaseProgress")
	end
	self.progress:ClearAllPoints()
	self.progress:SetPoint("BOTTOMLEFT", self.anchor, "TOPLEFT", 0, 0)
	self:UpdateProgress()
	self.progress:Show()
end

function B:Stop(message)
	self.order = nil
	if self.progress then self.progress:Hide() end
	for _, event in ipairs({ "BAG_UPDATE_DELAYED", "UI_ERROR_MESSAGE", "PLAYER_MONEY", "CURRENCY_DISPLAY_UPDATE" }) do self.events:UnregisterEvent(event) end
	if message and _G.UIErrorsFrame then _G.UIErrorsFrame:AddMessage(message, 1, 0.2, 0.2) end
end

function B:Close()
	self.offer = nil
	self:Stop()
	if self.stack then self.stack:Hide(); self.maximum:Hide() end
	if self.frame and self.frame.owner == self.proxy then self.frame:Hide() end
end

function B:NextPurchase()
	local order = self.order
	if not order or order.pending then return end
	if order.remaining == 0 then self:Stop(); return end
	local fresh = self:Read(order.offer.index)
	if not self:SameOffer(order.offer, fresh) or fresh.limit < order.offer.bundle then self:Stop(L["vendorBulkBuyStopped"]); return end
	local amount = math.min(order.remaining, fresh.chunk, fresh.limit)
	local delivery = { before = self:ItemCount(fresh.link), amount = amount }
	order.pending = delivery
	-- Never issue the next purchase until the previous delivery is visible in bags.
	BuyMerchantItem(fresh.index, amount)
	C_Timer.After(5, function()
		if B.order == order and order.pending == delivery then B:Stop(L["vendorBulkBuyStopped"]) end
	end)
end

function B:CheckDelivery()
	local order = self.order
	if not order or not order.pending then return end
	if self:ItemCount(order.offer.link) - order.pending.before < order.pending.amount then return end
	order.remaining = order.remaining - order.pending.amount
	order.pending = nil
	self:UpdateProgress()
	C_Timer.After(0.15, function() if B.order == order then B:NextPurchase() end end)
end

function B:Start(data)
	if self.order or self.offer ~= data.offer then return end
	local fresh = self:Read(data.offer.index)
	if not self:SameOffer(data.offer, fresh) or data.quantity < fresh.bundle or data.quantity > fresh.limit or data.quantity % fresh.bundle ~= 0 then
		self:Stop(L["vendorBulkBuyStopped"])
		return
	end
	self.offer = nil
	self.order = { offer = fresh, total = data.quantity, remaining = data.quantity }
	self:ShowProgress()
	for _, event in ipairs({ "BAG_UPDATE_DELAYED", "UI_ERROR_MESSAGE", "PLAYER_MONEY", "CURRENCY_DISPLAY_UPDATE" }) do self.events:RegisterEvent(event) end
	self:NextPurchase()
end

function B:Quantity()
	return self.frame.split
end

function B:Refresh()
	if not self.offer or not self.frame or self.order then return end
	if self.frame.owner ~= self.proxy or not self.frame:IsShown() then return end
	local fresh = self:Read(self.offer.index)
	if not self:SameOffer(self.offer, fresh) then self:Close(); return end
	self.frame.maxStack = fresh.limit
	self.frame.split = math.min(self.frame.split, fresh.limit)
	if self.frame.UpdateStackText then
		self.frame:UpdateStackText()
	else
		_G.StackSplitText:SetText(self.frame.split)
	end
	local left = self.frame.LeftButton or _G.StackSplitLeftButton
	local right = self.frame.RightButton or _G.StackSplitRightButton
	local okay = self.frame.OkayButton or _G.StackSplitOkayButton
	left:SetEnabled(self.frame.split > fresh.bundle)
	right:SetEnabled(self.frame.split < fresh.limit)
	okay:SetEnabled(self.frame.split >= fresh.bundle and self.frame.split <= fresh.limit)
end

function B:SetQuantity(quantity)
	local fresh = self.offer and self:Read(self.offer.index)
	if not self:SameOffer(self.offer, fresh) then self:Close(); return end
	self.frame.split = math.max(0, math.floor(math.min(quantity, fresh.limit) / fresh.bundle) * fresh.bundle)
	self.frame.typing = 0
	self:Refresh()
end

function B:SyncOwner()
	if self.frame.owner == self.proxy and self.offer then return end
	self.offer = nil
	local changedLayout = self.layout ~= nil
	self:RestoreLayout()
	if changedLayout and self.frame.ChooseFrameType then self.frame:ChooseFrameType(self.frame.minSplit) end
	self.stack:Hide()
	self.maximum:Hide()
end

function B:CreateDialog()
	if self.frame then return true end
	local frame = _G.StackSplitFrame
	if not frame then return end
	self.frame = frame
	-- A separate owner supplies the bulk callback without replacing any merchant
	-- button's SplitStack handler or any of the shared dialog's native scripts.
	self.proxy = CreateFrame("Frame", nil, UIParent)
	self.proxy.SplitStack = function(_, quantity)
		if B.offer then B:Start({ offer = B.offer, quantity = quantity }) end
	end
	local function button(label, callback)
		local widget = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		widget:SetSize(64, 24)
		widget:SetText(label)
		widget:SetScript("OnClick", callback)
		widget:SetScript("OnEnter", function()
			local fresh = B.offer and B:Read(B.offer.index)
			if not fresh then return end
			GameTooltip:SetOwner(widget, "ANCHOR_RIGHT")
			GameTooltip:AddLine(string.format(L["vendorBulkBuyLimit"], fresh.limit))
			GameTooltip:AddLine(B:CostText(fresh, B:Quantity()), 1, 1, 1, true)
			GameTooltip:Show()
		end)
		widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
		widget:Hide()
		return widget
	end
	self.stack = button(L["vendorBulkBuyStack"], function() if B.offer then B:SetQuantity(B.offer.stack) end end)
	self.maximum = button(L["vendorBulkBuyMax"], function()
		local fresh = B.offer and B:Read(B.offer.index)
		if fresh then B:SetQuantity(fresh.limit) end
	end)
	frame:HookScript("OnHide", function()
		B:RestoreLayout()
		B.stack:Hide()
		B.maximum:Hide()
		local offer = B.offer
		-- Blizzard hides the dialog before invoking owner.SplitStack on Okay.
		-- Defer cancellation until that synchronous purchase callback has run.
		C_Timer.After(0, function() if B.offer == offer then B.offer = nil end end)
	end)
	if frame.OpenStackSplitFrame then
		hooksecurefunc(frame, "OpenStackSplitFrame", function() B:SyncOwner() end)
	else
		hooksecurefunc("OpenStackSplitFrame", function() B:SyncOwner() end)
	end
	return true
end

function B:Open(button)
	if self.order then return end
	local data = self:Read(button:GetID())
	if not data or not self:CreateDialog() then return end
	self:Close()
	self.offer = data
	self.anchor = button
	self.proxy:ClearAllPoints()
	self.proxy:SetAllPoints(button)
	if self.frame.OpenStackSplitFrame then
		self.frame:OpenStackSplitFrame(math.max(data.bundle, data.limit), self.proxy, "BOTTOMLEFT", "TOPLEFT", data.bundle)
	else
		_G.OpenStackSplitFrame(math.max(data.bundle, data.limit), self.proxy, "BOTTOMLEFT", "TOPLEFT", data.bundle)
	end
	-- Keep exactly the merchant item's native anchoring, including page changes.
	self.frame:ClearAllPoints()
	self.frame:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 0)
	self:LayoutDialog()
	self.stack:Show()
	self.maximum:Show()
	self:SetQuantity(data.bundle)
end

function B:InstallHook()
	if self.hooked or not _G.MerchantItemButton_OnModifiedClick then return end
	self.hooked = true
	hooksecurefunc("MerchantItemButton_OnModifiedClick", function(button)
		if not B:Enabled() or not IsModifiedClick("SPLITSTACK") or IsModifiedClick("DRESSUP") or IsModifiedClick("EXPANDITEM") then return end
		-- Preserve Shift-linking into chat and other focused text inputs.
		local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
		if focus and focus:GetObjectType() == "EditBox" then return end
		B:Open(button)
	end)
end

B.events:RegisterEvent("ADDON_LOADED")
B.events:RegisterEvent("MERCHANT_SHOW")
B.events:RegisterEvent("MERCHANT_CLOSED")
B.events:RegisterEvent("MERCHANT_UPDATE")
B.events:SetScript("OnEvent", function(_, event)
	if event == "ADDON_LOADED" or event == "MERCHANT_SHOW" then
		B:InstallHook()
	elseif event == "MERCHANT_CLOSED" then
		B:Close()
	elseif event == "UI_ERROR_MESSAGE" then
		B:Stop(L["vendorBulkBuyStopped"])
	elseif B.order then
		if not B:SameOffer(B.order.offer, B:Read(B.order.offer.index)) then B:Close() else B:CheckDelivery() end
	elseif B.offer then
		B:Refresh()
	end
end)
B:InstallHook()
