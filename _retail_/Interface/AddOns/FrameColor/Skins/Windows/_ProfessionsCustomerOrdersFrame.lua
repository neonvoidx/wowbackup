local _, private = ...

-- Specify the options.
local options = {
  name = "_ProfessionsCustomerOrdersFrame",
  displayedName = "",
  order = 38,
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

  if C_AddOns.IsAddOnLoaded("Blizzard_ProfessionsCustomerOrders") then
    self:Apply(mainColor, backgroundColor, bordersColor, goldBorderColor, silverBorderColor, controlsColor, tabsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_ProfessionsCustomerOrders" then
        self:Apply(mainColor, backgroundColor, bordersColor, goldBorderColor, silverBorderColor, controlsColor, tabsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_ProfessionsCustomerOrders") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, goldBorderColor, silverBorderColor, controlsColor, tabsColor, desaturation)
  -- Main frames.
  for _, frame in pairs({
    ProfessionsCustomerOrdersFrame,
    ProfessionsCustomerOrdersFrame.MoneyFrameInset,
    ProfessionsCustomerOrdersFrame.Form.CurrentListings,
    ProfessionsCustomerOrdersFrame.Form.QualityDialog,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  -- Backgrounds.
  for _, texture in pairs({
    ProfessionsCustomerOrdersFrameBg,
    ProfessionsCustomerOrdersFrame.Form.CurrentListings.Bg
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

    -- The Border right to the MoneyFrameBorder
  for _, v in pairs({ProfessionsCustomerOrdersFrame.MoneyFrameBorder:GetRegions()}) do
    if v:IsObjectType("Texture") and not v:GetName() then
      v:SetDesaturation(desaturation)
      v:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    end
  end

  -- Borders.
  for _, frame in pairs({
    ProfessionsCustomerOrdersFrame.BrowseOrders.CategoryList,
    ProfessionsCustomerOrdersFrame.BrowseOrders.RecipeList,
    ProfessionsCustomerOrdersFrame.Form.LeftPanelBackground,
    ProfessionsCustomerOrdersFrame.Form.RightPanelBackground,
    ProfessionsCustomerOrdersFrame.Form.CurrentListings.OrderList,
    ProfessionsCustomerOrdersFrame.MyOrdersPage.OrderList,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, texture in pairs({
    ProfessionsCustomerOrdersFrame.Form.RecipeHeader,
    ProfessionsCustomerOrdersFrame.Form.PaymentContainer.NoteEditBox.Border,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Gold border.
  for _, texture in pairs({
    ProfessionsCustomerOrdersFrame.Form.PaymentContainer.TipMoneyInputFrame.GoldBox.Left,
    ProfessionsCustomerOrdersFrame.Form.PaymentContainer.TipMoneyInputFrame.GoldBox.Middle,
    ProfessionsCustomerOrdersFrame.Form.PaymentContainer.TipMoneyInputFrame.GoldBox.Right,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(goldBorderColor[1], goldBorderColor[2], goldBorderColor[3], goldBorderColor[4])
  end

  -- Silver border.
  for _, texture in pairs({
    ProfessionsCustomerOrdersFrame.Form.PaymentContainer.TipMoneyInputFrame.SilverBox.Left,
    ProfessionsCustomerOrdersFrame.Form.PaymentContainer.TipMoneyInputFrame.SilverBox.Middle,
    ProfessionsCustomerOrdersFrame.Form.PaymentContainer.TipMoneyInputFrame.SilverBox.Right,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(silverBorderColor[1], silverBorderColor[2], silverBorderColor[3], silverBorderColor[4])
  end

  for _, texture in pairs({
    ProfessionsCustomerOrdersFrameLeft,
    ProfessionsCustomerOrdersFrameMiddle,
    ProfessionsCustomerOrdersFrameRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Controls.
  for _, scrollFrame in pairs({
    ProfessionsCustomerOrdersFrame.BrowseOrders.CategoryList,
    ProfessionsCustomerOrdersFrame.BrowseOrders.RecipeList,
    ProfessionsCustomerOrdersFrame.Form.CurrentListings.OrderList,
    ProfessionsCustomerOrdersFrame.MyOrdersPage.OrderList,
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  for _, texture in pairs({
    ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.Background,
    ProfessionsCustomerOrdersFrame.Form.OrderRecipientDropdown.Background,
    ProfessionsCustomerOrdersFrame.Form.MinimumQuality.Dropdown.Background,
    ProfessionsCustomerOrdersFrame.Form.PaymentContainer.DurationDropdown.Background,
    ProfessionsCustomerOrdersFrame.Form.OrderRecipientTarget.Left,
    ProfessionsCustomerOrdersFrame.Form.OrderRecipientTarget.Middle,
    ProfessionsCustomerOrdersFrame.Form.OrderRecipientTarget.Right,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, box in pairs({
    ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.SearchBox,
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  -- Tabs.
  for _, tab in pairs({
    ProfessionsCustomerOrdersFrameBrowseTab,
    ProfessionsCustomerOrdersFrameOrdersTab,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
