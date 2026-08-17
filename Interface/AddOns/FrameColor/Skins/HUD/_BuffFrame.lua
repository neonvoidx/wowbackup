local _, private = ...

-- How far the border extends beyond the icon.
local BORDER_PADDING = 2

-- Specify the options.
local options = {
  name = "_BuffFrame",
  displayedName = "",
  order = 1,
  category = "HUD",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  self:Apply(self:GetColor("main"), true)
end

function skin:OnDisable()
  self:Apply(_, false)
end

function skin:Apply(mainColor, isEnable)
  for _, widget in pairs({ BuffFrame.AuraContainer:GetChildren() }) do
    if isEnable then
      widget.Icon:SetTexCoord(0.135, 0.865, 0.135, 0.865)
      self:ApplyBuffBorder(widget, mainColor)
    else
      widget.Icon:SetTexCoord(0, 1, 0, 1)
      if widget.border then
        widget.border:Hide()
      end
    end
  end
end

function skin:ApplyBuffBorder(widget, borderColor)
  if widget.border then
    widget.border:Show()
    widget.border:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    return
  end

  -- Create the border texture.
  -- A plain texture is used instead of a BackdropTemplate frame: the aura buttons
  -- hold secret values, so the size of anything parented to them is secret too and
  -- Blizzard's backdrop code errors out when it does math on it. Anchoring is fine,
  -- a texture just never reads its size in Lua.
  local border = widget:CreateTexture(nil, "BACKGROUND", nil, -8)
  border:SetColorTexture(1, 1, 1, 1)
  border:SetPoint("TOPLEFT", widget.Icon, "TOPLEFT", -BORDER_PADDING, BORDER_PADDING)
  border:SetPoint("BOTTOMRIGHT", widget.Icon, "BOTTOMRIGHT", BORDER_PADDING, -BORDER_PADDING)
  border:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])

  -- Save the border on the widget.
  widget.border = border
end
