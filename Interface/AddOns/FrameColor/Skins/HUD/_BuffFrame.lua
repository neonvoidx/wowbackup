local _, private = ...

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
    widget.border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    return
  end

  -- Create the border texture.
  local border = CreateFrame("Frame", nil, widget, "BackdropTemplate")
  border:SetPoint("TOPLEFT", widget.Icon, "TOPLEFT", -2, 2)
  border:SetPoint("BOTTOMRIGHT", widget.Icon, "BOTTOMRIGHT", 2, -2)

  -- Setup the backdrop.
  border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])

  -- Save the border on the widget.
  widget.border = border
end
