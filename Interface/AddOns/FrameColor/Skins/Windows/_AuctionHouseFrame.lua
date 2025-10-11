local _, private = ...

-- Specify the options.
local options = {
  name = "_AuctionHouseFrame",
  displayedName = "",
  order = 4,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.background,
    },
    ["borders"] = {
      order = 3,
      name = "",
      rgbaValues = private.colors.default.borders,
    },
    ["gold_border"] = {
      order = 3.1,
      name = "",
      rgbaValues = {1.0, 0.843, 0.0, 1.0},
    },
    ["silver_border"] = {
      order = 3.2,
      name = "",
      rgbaValues = {0.753, 0.753, 0.753, 1.0},
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
    ["tabs"] = {
      order = 5,
      name = "",
      rgbaValues = private.colors.default.tabs,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local bordersColor = self:GetColor("borders")
  local goldBorderColor = self:GetColor("gold_border")
  local silverBorderColor = self:GetColor("silver_border")
  local controlsColor = self:GetColor("controls")
  local tabsColor = self:GetColor("tabs")

  if C_AddOns.IsAddOnLoaded("Blizzard_AuctionHouseUI") then
    self:Apply(mainColor, backgroundColor, bordersColor, goldBorderColor, silverBorderColor, controlsColor, tabsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_AuctionHouseUI" then
        self:Apply(mainColor, backgroundColor, bordersColor, goldBorderColor, silverBorderColor, controlsColor, tabsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_AuctionHouseUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, goldBorderColor, silverBorderColor, controlsColor, tabsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(AuctionHouseFrame, mainColor, desaturation)

  -- Background.
  AuctionHouseFrameBg:SetDesaturation(desaturation)
  AuctionHouseFrameBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- The Border right to the MoneyFrameBorder
  for _, v in pairs({ AuctionHouseFrame.MoneyFrameBorder:GetRegions() }) do
    if v:IsObjectType("Texture") and not v:GetName() then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    end
  end

  -- Borders.
  for _, frame in pairs({
    AuctionHouseFrame.CategoriesList,
    AuctionHouseFrame.BrowseResultsFrame.ItemList,
    AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay,
    AuctionHouseFrame.CommoditiesBuyFrame.ItemList,
    AuctionHouseFrame.ItemSellFrame,
    AuctionHouseFrame.ItemSellList,
    AuctionHouseFrameAuctionsFrame.SummaryList,
    AuctionHouseFrameAuctionsFrame.AllAuctionsList,
    AuctionHouseFrameAuctionsFrame.BidsList,
    AuctionHouseFrame.CommoditiesSellFrame,
    AuctionHouseFrame.CommoditiesSellList,
    AuctionHouseFrame.MoneyFrameInset,
    AuctionHouseFrame.ItemBuyFrame.ItemDisplay,
    AuctionHouseFrame.ItemBuyFrame.ItemList,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, texture in pairs({
    AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.QuantityInput.InputBox.Left,
    AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.QuantityInput.InputBox.Middle,
    AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.QuantityInput.InputBox.Right,
    AuctionHouseFrame.ItemSellFrame.QuantityInput.InputBox.Left,
    AuctionHouseFrame.ItemSellFrame.QuantityInput.InputBox.Middle,
    AuctionHouseFrame.ItemSellFrame.QuantityInput.InputBox.Right,
    AuctionHouseFrameLeft,
    AuctionHouseFrameMiddle,
    AuctionHouseFrameRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Gold border.
  for _, texture in pairs({
    AuctionHouseFrame.ItemSellFrame.PriceInput.MoneyInputFrame.GoldBox.Left,
    AuctionHouseFrame.ItemSellFrame.PriceInput.MoneyInputFrame.GoldBox.Middle,
    AuctionHouseFrame.ItemSellFrame.PriceInput.MoneyInputFrame.GoldBox.Right,
    AuctionHouseFrame.ItemSellFrame.SecondaryPriceInput.MoneyInputFrame.GoldBox.Left,
    AuctionHouseFrame.ItemSellFrame.SecondaryPriceInput.MoneyInputFrame.GoldBox.Middle,
    AuctionHouseFrame.ItemSellFrame.SecondaryPriceInput.MoneyInputFrame.GoldBox.Right,
    AuctionHouseFrameAuctionsFrameGoldLeft,
    AuctionHouseFrameAuctionsFrameGoldMiddle,
    AuctionHouseFrameAuctionsFrameGoldRight,
    AuctionHouseFrameGoldLeft,
    AuctionHouseFrameGoldMiddle,
    AuctionHouseFrameGoldRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(goldBorderColor[1], goldBorderColor[2], goldBorderColor[3], goldBorderColor[4])
  end

  -- Silver border.
  for _, texture in pairs({
    AuctionHouseFrame.ItemSellFrame.PriceInput.MoneyInputFrame.SilverBox.Left,
    AuctionHouseFrame.ItemSellFrame.PriceInput.MoneyInputFrame.SilverBox.Middle,
    AuctionHouseFrame.ItemSellFrame.PriceInput.MoneyInputFrame.SilverBox.Right,
    AuctionHouseFrame.ItemSellFrame.SecondaryPriceInput.MoneyInputFrame.SilverBox.Left,
    AuctionHouseFrame.ItemSellFrame.SecondaryPriceInput.MoneyInputFrame.SilverBox.Middle,
    AuctionHouseFrame.ItemSellFrame.SecondaryPriceInput.MoneyInputFrame.SilverBox.Right,
    AuctionHouseFrameAuctionsFrameSilverLeft,
    AuctionHouseFrameAuctionsFrameSilverMiddle,
    AuctionHouseFrameAuctionsFrameSilverRight,
    AuctionHouseFrameSilverLeft,
    AuctionHouseFrameSilverMiddle,
    AuctionHouseFrameSilverRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(silverBorderColor[1], silverBorderColor[2], silverBorderColor[3], silverBorderColor[4])
  end

  -- Controls.
  for _, frame in pairs({
    AuctionHouseFrame.CategoriesList,
    AuctionHouseFrame.BrowseResultsFrame.ItemList,
    AuctionHouseFrame.ItemSellList,
    AuctionHouseFrameAuctionsFrame.SummaryList,
    AuctionHouseFrameAuctionsFrame.AllAuctionsList,
    AuctionHouseFrameAuctionsFrame.BidsList,
    AuctionHouseFrame.CommoditiesSellList,
    AuctionHouseFrame.CommoditiesBuyFrame.ItemList,
    AuctionHouseFrame.ItemBuyFrame.ItemList,
  }) do
    self:SkinScrollBarOf(frame, controlsColor, desaturation)
  end

  self:SkinBox(AuctionHouseFrame.SearchBar.SearchBox, controlsColor, desaturation)

  for _, texture in pairs({
    AuctionHouseFrame.SearchBar.FilterButton.Background,
    AuctionHouseFrame.ItemSellFrame.Duration.Dropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Tabs.
  for _, tab in pairs({
    AuctionHouseFrameBuyTab,
    AuctionHouseFrameSellTab,
    AuctionHouseFrameAuctionsTab,
    AuctionHouseFrameAuctionsFrameAuctionsTab,
    AuctionHouseFrameAuctionsFrameBidsTab,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
