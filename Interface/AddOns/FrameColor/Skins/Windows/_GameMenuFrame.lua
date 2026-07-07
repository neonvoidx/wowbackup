local _, private = ...

-- Specify the options.
local options = {
  name = "_GameMenuFrame",
  displayedName = "",
  order = 23,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["title_text"] = {
      order = 2.1,
      name = "",
      rgbaValues = {1, 1, 1, 1},
    },
    ["background"] = {
      order = 2,
      name = "",
      rgbaValues = {0, 0, 0, 0.7},
      hasAlpha = true,
      lockedColor = true,
    },
    ["controls"] = {
      order = 4,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
    ["button_highlight"] = {
      order = 4.1,
      name = "",
      rgbaValues = {0.98, 0.85, 0.45, 1},
      followClassColor = true,
      lockedColor = true,
    },
  },
  toggles = {
    ["skin_buttons"] = {
      order = 1,
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
  local buttonHighlightColor = self:GetColor("button_highlight")

  self:Apply(mainColor, backgroundColor, 1)

  -- Button are acquired once on show and are never returned to the pool.
  if self:GetToggleState("skin_buttons") then

    local function skinMenuButtons()
      for button in GameMenuFrame.buttonPool:EnumerateActive() do
        self:SkinButton(button, buttonHighlightColor, controlsColor, "auctionhouse-nav-button-select", 1)
      end
    end

    self:HookScript(GameMenuFrame, "OnShow", function()
      skinMenuButtons()
      self:Unhook(GameMenuFrame, "OnShow")
    end)

    skinMenuButtons()
  end
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, 0)

  for button in GameMenuFrame.buttonPool:EnumerateActive() do
    self:SkinButton(button, color, color, "128-RedButton-Highlight", 0)
  end
end

function skin:Apply(mainColor, backgroundColor, desaturation)
  -- Title.


  -- Main frame.
  self:SkinBorderOf(GameMenuFrame, mainColor, desaturation)

  for _, texture in pairs({
    GameMenuFrame.Header.LeftBG,
    GameMenuFrame.Header.CenterBG,
    GameMenuFrame.Header.RightBG,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Background.
  for _, texture in pairs({
    GameMenuFrame.Border.Bg
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetColorTexture(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
  end
end

function skin:SkinButton(button, buttonHighlightColor, color, highlightPath, desaturation)
  for _, v in pairs({
    "Left",
    "Center",
    "Right",
  }) do
    button[v]:SetDesaturation(desaturation)
    button[v]:SetVertexColor(color[1], color[2], color[3], color[4])
  end
  button:SetHighlightTexture(highlightPath)
  local highlightTex = button:GetHighlightTexture()
  highlightTex:SetDesaturation(desaturation)
  highlightTex:SetVertexColor(buttonHighlightColor[1], buttonHighlightColor[2], buttonHighlightColor[3], buttonHighlightColor[4])
end



