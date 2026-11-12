local _, private = ...
-- @ TODO Check why money borders can't be found in _G anymore.

-- Specify the options.
local options = {
  name = "_TradeFrame",
  displayedName = "",
  order = 46,
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
    --[[
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
    ["copper_border"] = {
      order = 3.3,
      name = "",
      rgbaValues = {0.722, 0.451, 0.200, 1.0},
    },
    ]]
  },
  toggles = {
    ["follow_unit_class_or_reaction_color"] = {
      order = 1,
      name = "",
      isChecked = true,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local function handleBackgrounds()
    if TradeFrame.PlayerTradeBG then
      TradeFrame.PlayerTradeBG:Show()
      return
    end

    local layer, sublayer = TradeRecipientBG:GetDrawLayer()
    TradeFrame.PlayerTradeBG = TradeFrame:CreateTexture(nil, layer, nil, sublayer)
    TradeFrame.PlayerTradeBG:ClearAllPoints()
    TradeFrame.PlayerTradeBG:SetPoint("TOPLEFT",TradeFrameBg,"TOPLEFT")
    TradeFrame.PlayerTradeBG:SetPoint("BOTTOMRIGHT",TradeRecipientBG,"BOTTOMLEFT")
    TradeFrame.PlayerTradeBG:SetTexture(TradeFrameBg:GetTexture())
  end

  if self:GetToggleState("follow_unit_class_or_reaction_color") then
    handleBackgrounds()
    self:RegisterForEvent("TRADE_SHOW", self.UpdateRecipientBG)
    self:UpdateRecipientBG()
  end

  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("borders"), self:GetColor("gold_border"), self:GetColor("silver_border"), self:GetColor("copper_border"),  1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, color, color, 0)

  if TradeFrame.PlayerTradeBG then
    TradeFrame.PlayerTradeBG:Hide()
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, goldColor, silverColor, copperColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(TradeFrame, mainColor, desaturation)

  for _, texture in pairs({
    TradeFrame.RecipientOverlay.portraitFrame,
    TradeRecipientLeftBorder,
    TradeRecipientBotLeftCorner,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Background.
  for _, texture in pairs({
    TradeFrameBg,
    TradeRecipientBG,
    TradeFrame.PlayerTradeBG, -- In case it exists but should no longer be class colored.
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  if self:GetToggleState("follow_unit_class_or_reaction_color") then
    for _, texture in pairs({
      TradeFrame.PlayerTradeBG
    }) do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(unpack(self:GetUnitColor("player")))
    end
  end

  -- Borders.
  for _, frame in pairs({
    TradeFrameInset,
    TradePlayerItemsInset,
    TradePlayerEnchantInset,
    TradePlayerInputMoneyInset,
    TradeRecipientItemsInset,
    TradeRecipientEnchantInset,
    TradeRecipientMoneyInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  --[[

  -- Money Borders.
  for _, texture in pairs({
    TradePlayerInputMoneyFrameGoldLeft,
    TradePlayerInputMoneyFrameGoldMiddle,
    TradePlayerInputMoneyFrameGoldRight,
    TradeRecipientMoneyBgLeft,
    TradeRecipientMoneyBgMiddle,
    TradeRecipientMoneyBgRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(goldColor[1], goldColor[2], goldColor[3], goldColor[4])
  end

  for _, texture in pairs({
    TradePlayerInputMoneyFrameSilverLeft,
    TradePlayerInputMoneyFrameSilverMiddle,
    TradePlayerInputMoneyFrameSilverRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(silverColor[1], silverColor[2], silverColor[3], silverColor[4])
  end

  for _, texture in pairs({
    TradePlayerInputMoneyFrameCopperLeft,
    TradePlayerInputMoneyFrameCopperMiddle,
    TradePlayerInputMoneyFrameCopperRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(copperColor[1], copperColor[2], copperColor[3], copperColor[4])
  end
    ]]
end


function skin:UpdateRecipientBG()
  local color = skin:GetUnitColor("NPC") -- At TradeFrame show NPC holds the trade target class.

  TradeRecipientBG:SetVertexColor(color[1], color[2], color[3], color[4])
end


