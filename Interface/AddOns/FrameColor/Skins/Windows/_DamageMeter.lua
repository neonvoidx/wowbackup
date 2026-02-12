local _, private = ...

-- Specify the options.
local options = {
  name = "_DamageMeter",
  displayedName = "",
  order = 53,
  category = "Windows",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
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
  },
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local bordersColor = self:GetColor("borders")
  local controlsColor = self:GetColor("controls")
  -- Apply the skin to all current session windows.
  self:Apply(mainColor, bordersColor, controlsColor, 1)
  -- Hook SetupSessionWindow to skin new seassion windows.
  self:HookFunc(DamageMeter, "SetupSessionWindow", function(_, _, windowIndex)
    self:SkinSessionWindow(windowIndex, mainColor, bordersColor, controlsColor, 1)
  end)
end

function skin:OnDisable()
  local color = {1, 1, 1, 1}
  self:Apply(color, color, color, 0)
end

function skin:Apply(mainColor, bordersColor, controlsColor, desaturation)
  local max_session_window_count = DamageMeterMixin:GetMaxSessionWindowCount()
  for i=1, max_session_window_count do
    self:SkinSessionWindow(i, mainColor, bordersColor, controlsColor, desaturation)
  end
end

function skin:SkinSessionWindow(index, mainColor, bordersColor, controlsColor, desaturation)
  local sessionWindow = _G["DamageMeterSessionWindow" .. index]

  if not sessionWindow then
    return
  end

  -- Main / Header.
  sessionWindow.Header:SetDesaturation(desaturation)
  sessionWindow.Header:SetVertexColor(mainColor[1], mainColor[2], mainColor[3], mainColor[4])

  -- Border / Source Window Border.
  sessionWindow.SourceWindow.Background:SetDesaturation(desaturation)
  sessionWindow.SourceWindow.Background:SetVertexColor(bordersColor[1], bordersColor[2], bordersColor[3], bordersColor[4])

  -- Controls.
  for _, frame in pairs({
    sessionWindow,
    sessionWindow.SourceWindow,
  }) do
    self:SkinScrollBarOf(frame, controlsColor, desaturation)
  end
end
