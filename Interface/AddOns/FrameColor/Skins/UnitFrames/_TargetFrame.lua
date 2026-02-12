local _, private = ...

-- Specify the options.
local options = {
  name = "_TargetFrame",
  displayedName = "",
  order = 2,
  category = "UnitFrames",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["cast_bar"] = {
      order = 2,
      name = "",
      rgbaValues = private.colors.default.main,
    },
    ["buff_border"] ={
      order = 3,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
  toggles = {
    ["follow_unit_class_or_reaction_color"] = {
      name = "",
      isChecked = false,
    },
    ["show_buff_border"] = {
      name = "",
      isChecked = true,
    },
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)
local skinnedWidgets = {}

function skin:OnEnable()
  if self:GetToggleState("follow_unit_class_or_reaction_color") then
    self:RegisterForEvent("PLAYER_TARGET_CHANGED", skin.UpdateToUnitColor)
    skin:UpdateToUnitColor()
  else
    skin:Apply(self:GetColor("main"), self:GetColor("cast_bar"), 1)
  end

  if self:GetToggleState("show_buff_border") then
    local borderColor = self:GetColor("buff_border")
    local buffPool = TargetFrame.auraPools:GetPool("TargetBuffFrameTemplate")

    skinnedWidgets = {}

    local function updateBorders()
      for widget in buffPool:EnumerateActive() do
        if not skinnedWidgets[widget] then
          widget.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
          self:ApplyBuffBorder(widget, borderColor)
          skinnedWidgets[widget] = true
        end
      end
    end

    self:HookFunc(TargetFrame, "UpdateAuras", updateBorders)
    updateBorders()
  end
end

function skin:OnDisable()
  local color = {1,1,1,1}
  self:Apply(color, color, 0)

  for widget, _ in pairs(skinnedWidgets) do
    widget.Icon:SetTexCoord(0, 1, 0, 1)
    widget.border:Hide()
  end
end

function skin:Apply(color, castBarColor, desaturation)
  -- Main frame.
  local texture = TargetFrame.TargetFrameContainer.FrameTexture
  texture:SetDesaturation(desaturation)
  texture:SetVertexColor(color[1], color[2], color[3], color[4])

  -- Castbar.
  for _, texture in pairs({
    TargetFrameSpellBar.Border,
    TargetFrameSpellBar.Background,
  }) do
    texture:SetDesaturation(desaturation)
    texture:SetVertexColor(castBarColor[1], castBarColor[2], castBarColor[3], castBarColor[4])
  end
end

function skin:UpdateToUnitColor()
  local color = skin:GetUnitColor("target")
  local texture = TargetFrame.TargetFrameContainer.FrameTexture
  texture:SetDesaturation(1)
  texture:SetVertexColor(color[1], color[2], color[3], color[4])
end

function skin:ApplyBuffBorder(widget, borderColor)
  if widget.border then
    widget.border:Show()
    widget.border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    return
  end

  -- Create the border texture.
  local border = CreateFrame("Frame", nil, widget, "BackdropTemplate")
  border:SetPoint("TOPLEFT", widget, "TOPLEFT", -2, 2)
  border:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 2, -2)

  -- Setup the backdrop.
  border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
  })
  border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])

  -- Save the border on the widget.
  widget.border = border
end
