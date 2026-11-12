local _, private = ...

-- Specify the options.
local options = {
  name = "_PopUpDialogs",
  displayedName = "",
  order = 11,
  category = "HUD",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
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
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  self:Apply(self:GetColor("main"), self:GetColor("gold_border"), self:GetColor("silver_border"), self:GetColor("copper_border"), self:GetColor("controls"),  1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, color, color, 0)
end

function skin:Apply(mainColor, goldBorderColor, silverBorderColor, copperBorderColor, controlsColor, desaturation)
  -- Main frames.
  for _, frame in pairs({
    LFGDungeonReadyDialog,
    LFGDungeonReadyStatus,
    LFGListInviteDialog,
    LFGInvitePopup,
    LFDRoleCheckPopup,
    PVPReadyDialog,
    RolePollPopup,
    ReadyStatus,
  }) do
    self:SkinBorderOf(frame, mainColor, desaturation)
  end

  --Static Popup Borders
  for _, texture in pairs({
    StaticPopup1.BG.Top,
    StaticPopup2.BG.Top,
    StaticPopup3.BG.Top,
    StaticPopup4.BG.Top,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  for i=1, 4 do
    -- Money borders.
    -- Gold.
    for _, texture in pairs({
      _G["StaticPopup" .. i .. "MoneyInputFrameGoldLeft"],
      _G["StaticPopup" .. i .. "MoneyInputFrameGoldMiddle"],
      _G["StaticPopup" .. i .. "MoneyInputFrameGoldRight"],
    }) do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(goldBorderColor[1], goldBorderColor[2], goldBorderColor[3], goldBorderColor[4])
    end

    -- Silver.
    for _, texture in pairs({
      _G["StaticPopup" .. i .. "MoneyInputFrameSilverLeft"],
      _G["StaticPopup" .. i .. "MoneyInputFrameSilverMiddle"],
      _G["StaticPopup" .. i .. "MoneyInputFrameSilverRight"],
    }) do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(silverBorderColor[1], silverBorderColor[2], silverBorderColor[3], silverBorderColor[4])
    end

    -- Copper.
    for _, texture in pairs({
      _G["StaticPopup" .. i .. "MoneyInputFrameCopperLeft"],
      _G["StaticPopup" .. i .. "MoneyInputFrameCopperMiddle"],
      _G["StaticPopup" .. i .. "MoneyInputFrameCopperRight"],
    }) do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(copperBorderColor[1], copperBorderColor[2], copperBorderColor[3], copperBorderColor[4])
    end

    -- Controls.
    -- EditBox.
    for _, texture in pairs({
      _G["StaticPopup" .. i .. "EditBoxLeft"],
      _G["StaticPopup" .. i .. "EditBoxMid"],
      _G["StaticPopup" .. i .. "EditBoxRight"],
    }) do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    end

    -- Dropdown.
    for _, texture in pairs({
      _G["StaticPopup" .. i].Dropdown.Background,
    }) do
      texture:SetDesaturation(desaturation)
      texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
    end
  end
end


