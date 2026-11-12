local _, private = ...

-- Specify the options.
local options = {
  name = "_Change_To_SkinName",
  displayedName = "",
  order = 1,
  category = "Change_To_SkinCategory",
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
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local bordersColor = self:GetColor("borders")
  local controlsColor = self:GetColor("controls")
  local tabsColor = self:GetColor("tabs")

  if C_AddOns.IsAddOnLoaded("Change_To_AddOnName") then
    self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Change_To_AddOnName" then
        self:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Change_To_AddOnName") then
    local color = {1, 1, 1, 1}
    self:Apply(color, color, color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, bordersColor, controlsColor, tabsColor, desaturation)

end
