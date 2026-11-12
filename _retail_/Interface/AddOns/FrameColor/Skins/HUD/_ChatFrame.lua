local _, private = ...

-- Specify the options.
local options = {
  name = "_ChatFrame",
  displayedName = "",
  order = 6,
  category = "HUD",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["background"] = {
      order = 2,
      name = "",
      rgbaValues = {0.1, 0.1, 0.1}, -- Alpha is not used since it is controlled by FCF_SetWindowAlpha and i don't want to change the behavior.
    },
    ["borders"] = {
      order = 3,
      name = "",
      hasAlpha = true,
      rgbaValues = {0.2, 0.2, 0.2, 0.6},
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
    ["btn_normal_color"] = {
      order = 6,
      name = "",
      rgbaValues = {0.5, 0.5, 0.5, 1},
    },
    ["btn_highlight_color"] = {
      order = 7,
      name = "",
      rgbaValues = {1, 1, 1, 1},
    },
    ["btn_pushed_color"] = {
      order = 8,
      name = "",
      rgbaValues = {0.3, 0.3, 0.3, 1},
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local bordersColor = self:GetColor("borders")
  local controlsColor = self:GetColor("controls")
  local tabsColor = self:GetColor("tabs")
  local normalBtnColor = self:GetColor("btn_normal_color")
  local highlightBtnColor = self:GetColor("btn_highlight_color")
  local pushedBtnColor = self:GetColor("btn_pushed_color")

  -- Apply to all present windows.
  self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, normalBtnColor, highlightBtnColor, pushedBtnColor, 1)

  -- Hook to apply for future updates.
  self:HookFunc("ChatFrame_AddMessageGroup", function(chatFrame)
    self:ApplyToChatFrame(chatFrame:GetName(), mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
  end)

  -- Restore the colors on change.
  self:HookFunc("FCF_SetWindowColor", function(frame)
    self:ReapplyColors(frame:GetName(), backgroundColor, bordersColor)
  end)
end

function skin:OnDisable()
  -- Not the exact colors but the next FCF_SetWindowColor will restore it anyways.
  local color = {1, 1, 1, 1}
  self:Apply(color, {0,0,0,1}, color, color, color, color, color, color, 0)
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, normalBtnColor, highlightBtnColor, pushedBtnColor, desaturation)
  -- Main frame.
  for i=1, NUM_CHAT_WINDOWS do
    self:ApplyToChatFrame("ChatFrame" .. i, mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  end

  -- Buttons
  local normalTextures = {
    QuickJoinToastButton.FriendsButton,
    ChatFrameChannelButton.Icon,
  }
  local highlightTextures = {}
  local pushedTextures = {}

  for _, btn in pairs ({
    QuickJoinToastButton,
    ChatFrameChannelButton,
    ChatFrameMenuButton,
  }) do
    table.insert(normalTextures, btn:GetNormalTexture())
    table.insert(highlightTextures, btn:GetHighlightTexture())
    table.insert(pushedTextures, btn:GetPushedTexture())
  end

  for _, texture in pairs(normalTextures) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(normalBtnColor[1], normalBtnColor[2], normalBtnColor[3], normalBtnColor[4])
  end

  for _, texture in pairs(highlightTextures) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(highlightBtnColor[1], highlightBtnColor[2], highlightBtnColor[3], highlightBtnColor[4])
  end

  for _, texture in pairs(pushedTextures) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(pushedBtnColor[1], pushedBtnColor[2], pushedBtnColor[3], pushedBtnColor[4])
  end

end

function skin:ApplyToChatFrame(ChatFrame, mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)
  -- Edit Box.
  for _, texture in pairs({
    _G[ChatFrame .. "EditBoxLeft"],
    _G[ChatFrame .. "EditBoxMid"],
    _G[ChatFrame .. "EditBoxRight"],
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])
  end

  -- Background.
  for _, texture in pairs({
    _G[ChatFrame .. "Background"],
    _G[ChatFrame .. "ButtonFrameBackground"],
  }) do
    local oldAlpha = texture:GetAlpha()
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], oldAlpha)
  end

  -- Borders.
  for _, frameName in pairs({
    ChatFrame,
    ChatFrame .. "ButtonFrame",
  }) do
    self:SkinBorderOf(frameName, bordersColor, desaturation)
  end

  -- Controls.
  for _, scrollFrame in pairs({
    _G[ChatFrame],
  }) do
    self:SkinScrollBarOf(scrollFrame, controlsColor, desaturation)
    local ScrollToBottomButtonTexture = _G[ChatFrame].ScrollToBottomButton:GetNormalTexture()
    ScrollToBottomButtonTexture:SetDesaturation(desaturation)
    ScrollToBottomButtonTexture:SetVertexColor(controlsColor[1], controlsColor[2], controlsColor[3], controlsColor[4])
  end

  -- Tabs.
  self:SkinTabs(_G[ChatFrame .. "Tab"], tabsColor, desaturation)
end

function skin:ReapplyColors(ChatFrame, backgroundColor, bordersColor)
  -- Background.
  for _, texture in pairs({
    _G[ChatFrame .. "Background"],
    _G[ChatFrame .. "ButtonFrameBackground"],
  }) do
    local oldAlpha = texture:GetAlpha()
    texture:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], oldAlpha)
  end

  -- Borders.
  for _, frameName in pairs({
    ChatFrame,
    ChatFrame .. "ButtonFrame",
  }) do
    self:SkinBorderOf(frameName, bordersColor, 1)
  end
end
