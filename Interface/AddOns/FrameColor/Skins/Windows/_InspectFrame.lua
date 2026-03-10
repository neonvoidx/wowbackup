local _, private = ...

-- Specify the options.
local options = {
  name = "_InspectFrame",
  displayedName = "",
  order = 25,
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
  toggles = {
    ["follow_unit_class_or_reaction_color"] = {
      order = 1,
      name = "",
      isChecked = true,
    }
  }
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local bordersColor = self:GetColor("borders")
  local tabsColor = self:GetColor("tabs")
  local updateBg = self:GetToggleState("follow_unit_class_or_reaction_color")

  if C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then
    self:Apply(mainColor, backgroundColor, bordersColor, tabsColor, 1)
    if updateBg then
      self:HookFunc("InspectFrame_Show", self.UpdateBgToUnitClassColor)
      self:UpdateBgToUnitClassColor()
    end
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_InspectUI" then
        self:Apply(mainColor, backgroundColor, bordersColor, tabsColor, 1)
        if updateBg then
          self:HookFunc("InspectFrame_Show", self.UpdateBgToUnitClassColor)
          self:UpdateBgToUnitClassColor()
        end
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, tabsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(InspectFrame, mainColor, desaturation)

  for _, texture in pairs({
    InspectFrameInset.Bg, -- No mistake. I only want the InspectFrameBg border to change to backgroundColor.
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Background.
  for _, texture in pairs({
    InspectFrameBg,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  self:SkinNineSliced(InspectFrameInset, bordersColor, desaturation)

  for _, texture in pairs({
    InspectModelFrameBorderBottom,
    InspectModelFrameBorderBottomRight,
    InspectModelFrameBorderBottomLeft,
    InspectModelFrameBorderTop,
    InspectModelFrameBorderTopLeft,
    InspectModelFrameBorderTopRight,
    InspectModelFrameBorderLeft,
    InspectModelFrameBorderRight,
    InspectTrinket0SlotFrame,
    InspectTrinket1SlotFrame,
    InspectFinger0SlotFrame,
    InspectFinger1SlotFrame,
    InspectFeetSlotFrame,
    InspectLegsSlotFrame,
    InspectWaistSlotFrame,
    InspectHandsSlotFrame,
    InspectWristSlotFrame,
    InspectSecondaryHandSlotFrame,
    InspectMainHandSlotFrame,
    InspectTabardSlotFrame,
    InspectShirtSlotFrame,
    InspectChestSlotFrame,
    InspectBackSlotFrame,
    InspectShoulderSlotFrame,
    InspectNeckSlotFrame,
    InspectHeadSlotFrame
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
  end

  -- Tabs.
  for _, tab in pairs({
    InspectFrameTab1,
    InspectFrameTab2,
    InspectFrameTab3,
    InspectPaperDollItemsFrame.InspectTalents
  }) do
    self:SkinTabs(tab, tabsColor, desaturation)
  end
end

function skin:UpdateBgToUnitClassColor()
  local color = skin:GetUnitColor(INSPECTED_UNIT or "target") -- self is not passed.

  for _, texture in pairs({
    InspectFrameBg,
  }) do
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end


