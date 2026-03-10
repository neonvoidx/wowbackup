local _, private = ...

-- Specify the options.
local options = {
  name = "_MailFrame",
  displayedName = "",
  order = 33,
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
    ["copper_border"] = {
      order = 3.3,
      name = "",
      rgbaValues = {0.722, 0.451, 0.200, 1.0},
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
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("borders"), self:GetColor("controls"), self:GetColor("tabs"), self:GetColor("gold_border"), self:GetColor("silver_border"), self:GetColor("copper_border"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, goldColor, silverColor, copperColor, desaturation)
  -- Main frames.
  for _, frame in pairs({
    MailFrame,
    OpenMailFrame,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  for _, texture in pairs({
    OpenMailHorizontalBarLeft,
    SendMailHorizontalBarLeft,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

    -- This is for the HorizontalBarRight textures. They are unnamed.
    -- Also contains SendMailHorizontalBarLeft2 due to %d.
  for _, frame in pairs({
    SendMailFrame,
    OpenMailFrame,
  }) do
    for _, v in pairs({ frame:GetRegions() }) do
      if v:IsObjectType("Texture") and v:GetDebugName():match("%d") then
        v:SetDesaturation(desaturation)
        v:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
      end
    end
  end

  -- Backgrounds.
  for _, texture in pairs({
    MailFrameBg,
    OpenMailFrameBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  for _, frame in pairs({
    MailFrameInset,
    OpenMailFrameInset,
    SendMailMoneyInset,
  }) do
    self:SkinNineSliced(frame, bordersColor, desaturation)
  end

  for _, texture in pairs({
    SendMailNameEditBoxLeft,
    SendMailNameEditBoxMiddle,
    SendMailNameEditBoxRight,
    SendMailSubjectEditBoxLeft,
    SendMailSubjectEditBoxMiddle,
    SendMailSubjectEditBoxRight,
    SendMailMoneyBgLeft,
    SendMailMoneyBgMiddle,
    SendMailMoneyBgRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Money Borders.
  for _, texture in pairs({
    SendMailMoneyGoldLeft,
    SendMailMoneyGoldMiddle,
    SendMailMoneyGoldRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(goldColor[1], goldColor[2], goldColor[3], goldColor[4])
  end

  for _, texture in pairs({
    SendMailMoneySilverLeft,
    SendMailMoneySilverMiddle,
    SendMailMoneySilverRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(silverColor[1], silverColor[2], silverColor[3], silverColor[4])
  end

  for _, texture in pairs({
    SendMailMoneyCopperLeft,
    SendMailMoneyCopperMiddle,
    SendMailMoneyCopperRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(copperColor[1], copperColor[2], copperColor[3], copperColor[4])
  end

  -- Controls.
  for _, scrollFrame in pairs({
    OpenMailScrollFrame,
    SendMailScrollFrame
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
  end

  -- Tabs.
  for _, tab in pairs({
    MailFrameTab1,
    MailFrameTab2,
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end
