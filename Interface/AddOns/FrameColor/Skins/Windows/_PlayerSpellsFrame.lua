local _, private = ...

-- Specify the options.
local options = {
  name = "_PlayerSpellsFrame",
  displayedName = "",
  order = 36,
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
      name = "",
      isChecked = true,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local controlsColor = self:GetColor("controls")
  local tabsColor = self:GetColor("tabs")

  local function checkFollow()
    if self:GetToggleState("follow_unit_class_or_reaction_color") then
      self:HookFunc(PlayerSpellsFrame, "SetInspecting", self.SetBottomBarToUnitColor)
      self:HookFunc(PlayerSpellsFrame, "ClearInspectUnit", self.SetBottomBarToUnitColor)
      self:SetBottomBarToUnitColor()
    end
  end

  if C_AddOns.IsAddOnLoaded("Blizzard_PlayerSpells") then
    self:Apply(mainColor, backgroundColor, controlsColor, tabsColor, 1)
    checkFollow()
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_PlayerSpells" then
        self:Apply(mainColor, backgroundColor, controlsColor, tabsColor, 1)
        checkFollow()
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_PlayerSpells") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, controlsColor, tabsColor, desaturation)
  -- Main frames.
  for _, frame in pairs({
    PlayerSpellsFrame,
    HeroTalentsSelectionDialog,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  for _, frame in pairs({
    ClassTalentLoadoutImportDialog,
    ClassTalentLoadoutEditDialog,
    ClassTalentLoadoutCreateDialog
  }) do
    self:SkinBorderOf(frame, mainColor, desaturation)
  end

  -- Background.
  for _, texture in pairs({
    PlayerSpellsFrameBg,
    PlayerSpellsFrame.SpecFrame.BlackBG,
    PlayerSpellsFrame.SpecFrame.Background,
    PlayerSpellsFrame.TalentsFrame.BottomBar,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Borders.
  -- Ring Textures, looks bad due to SetVertexColor leaving artifacts of the old color.
  --[[
  for _, v in pairs({ PlayerSpellsFrame.SpecFrame:GetChildren() }) do
    for _, child in pairs({ v:GetChildren() }) do
      if type(child) == "table" and child.Ring then
        child.Ring:SetDesaturation(desaturation)
        child.Ring:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])
      end
    end
  end
  --]]

  -- Controls.
  for _, texture in pairs({
    PlayerSpellsFrame.TalentsFrame.LoadSystem.Dropdown.Background,
    PlayerSpellsFrame.TalentsFrame.WarmodeButton.Ring,
    PlayerSpellsFrame.TalentsFrame.SearchPreviewContainer.LeftBorder,
    PlayerSpellsFrame.TalentsFrame.SearchPreviewContainer.RightBorder,
    PlayerSpellsFrame.TalentsFrame.SearchPreviewContainer.BorderAnchor,
    PlayerSpellsFrame.TalentsFrame.SearchPreviewContainer.BotRightCorner,
    PlayerSpellsFrame.TalentsFrame.SearchPreviewContainer.BottomBorder
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  for _, box in pairs({
    PlayerSpellsFrame.TalentsFrame.SearchBox,
    PlayerSpellsFrame.SpellBookFrame.SearchBox,
    ClassTalentLoadoutEditDialog.NameControl.EditBox,
    ClassTalentLoadoutCreateDialog.NameControl.EditBox,
    ClassTalentLoadoutImportDialog.NameControl.EditBox
  }) do
    self:SkinBox(box, controlsColor, desaturation)
  end

  self:SkinBorderOf(ClassTalentLoadoutImportDialog.ImportControl.InputContainer, controlsColor, desaturation)

  -- Tabs.
  for _, tabSystem in pairs({
    PlayerSpellsFrame.TabSystem,
    PlayerSpellsFrame.SpellBookFrame.CategoryTabSystem,
  }) do
    for _, tab in pairs({ tabSystem:GetChildren() }) do
      for _, texture in pairs({
        tab.Left,
        tab.Middle,
        tab.Right,
      }) do
        texture:SetDesaturation(desaturation)
        texture:SetVertexColor(tabsColor[1], tabsColor[2], tabsColor[3], tabsColor[4])
      end
    end
  end
end

function skin:SetBottomBarToUnitColor()
  local unit = PlayerSpellsFrame:IsInspecting() and PlayerSpellsFrame.inspectUnit or "player"

  local color = skin:GetUnitColor(unit)

  for _, texture in pairs({
    PlayerSpellsFrame.TalentsFrame.BottomBar,
  }) do
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
end
