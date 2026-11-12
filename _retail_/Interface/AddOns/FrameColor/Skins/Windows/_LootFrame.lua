local _, private = ...

-- Specify the options.
local options = {
  name = "_LootFrame",
  displayedName = "",
  order = 31,
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
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  self:Apply(self:GetColor("main"), self:GetColor("background"), self:GetColor("controls"), 1)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, controlsColor, desaturation)
  -- Main frames.
  for _, frame in pairs({
    LootFrame,
    GroupLootHistoryFrame,
  }) do
    self:SkinNineSliced(frame, mainColor, desaturation)
  end

  -- Backgrounds.
  for _, texture in pairs({
    LootFrameBg.TopSection,
    LootFrameBg.BottomEdge,
    GroupLootHistoryFrameBg.TopSection,
    GroupLootHistoryFrameBg.BottomEdge,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

    -- Same as with bags. The corners will render invisible when calling SetVertexColor on them.
  for _, texture in pairs({
    LootFrameBg.BottomRight,
    LootFrameBg.BottomLeft,
    GroupLootHistoryFrameBg.BottomLeft,
    GroupLootHistoryFrameBg.BottomRight,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetColorTexture(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end

  -- Controls.
  for _, frame in pairs({
    LootFrame,
    GroupLootHistoryFrame,
  }) do
    self:SkinScrollBarOf(frame, controlsColor, desaturation)
  end

  for _, texture in pairs({
    -- @TODO add GroupLootHistoryFrame dropdown.
    GroupLootHistoryFrame.EncounterDropdown.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end
end
