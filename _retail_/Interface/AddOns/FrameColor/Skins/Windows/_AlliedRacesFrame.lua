local _, private = ...

local options = {
  order = 3,
  name = "_AlliedRacesFrame",
  displayedName = "",
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
      order = 3,
      name = "",
      rgbaValues = private.colors.default.controls,
    },
  }
}

-- Register the Skin
local skin = private:RegisterSkin(options)

function skin:OnEnable()
  local mainColor = self:GetColor("main")
  local backgroundColor = self:GetColor("background")
  local controlsColor = self:GetColor("controls")

  if C_AddOns.IsAddOnLoaded("Blizzard_AlliedRacesUI") then
    self:Apply(mainColor, backgroundColor, controlsColor, 1)
  else
    local function onAddonLoaded(_, addOnName)
      if addOnName == "Blizzard_AlliedRacesUI" then
        self:Apply(mainColor, backgroundColor, controlsColor, 1)
        self:UnregisterFromEvent("ADDON_LOADED", onAddonLoaded)
      end
    end
    self:RegisterForEvent("ADDON_LOADED", onAddonLoaded)
  end
end

function skin:OnDisable()
  if C_AddOns.IsAddOnLoaded("Blizzard_AlliedRacesUI") then
    local color = {1, 1 ,1, 1}
    self:Apply(color, color, color, 0)
  end
end

function skin:Apply(mainColor, backgroundColor, controlsColor, desaturation)
  -- Main frame.
  self:SkinNineSliced(AlliedRacesFrame, mainColor, desaturation)

  -- Background.
  AlliedRacesFrameBg:SetDesaturation(desaturation)
  AlliedRacesFrameBg:SetVertexColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])

  -- Controls.
  self:SkinScrollBarOf(AlliedRacesFrame.RaceInfoFrame.ScrollFrame, controlsColor, desaturation)
end
