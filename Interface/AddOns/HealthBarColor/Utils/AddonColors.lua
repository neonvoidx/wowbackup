local _, addonTable = ...
local addon = addonTable.addon

addonTable.classColors = {}
addonTable.reactionColors = {}
addonTable.selectionColors = {}
addonTable.powerColors = {}
addonTable.debuffColors = {}
addonTable.colorMixins = {}

local function get_rgb(colorTable)
  return colorTable.r, colorTable.g, colorTable.b, colorTable.a
end

function addon:UpdateAddonColors()
  --[[
    Copy is important for profile switching as the old profile no longer exists after that and the colors inside the hbc_units would point to nil
    ]]
  addonTable.colorMixins = {}
  -- Class
  addonTable.classColors = CopyTable(self.db.profile.addonColors.classColors)
  addonTable.colorMixins.classColors = {}
  for class, colorTable in pairs(addonTable.classColors) do
    addonTable.colorMixins.classColors[class] = {}
    addonTable.colorMixins.classColors[class].classColorStart = CreateColor(get_rgb(colorTable.classColorStart))
    addonTable.colorMixins.classColors[class].classColorEnd = CreateColor(get_rgb(colorTable.classColorEnd))
  end
  -- Reaction
  addonTable.reactionColors = CopyTable(self.db.profile.addonColors.reactionColors)
  addonTable.colorMixins.reactionColors = {}
  for reaction, colorTable in pairs(addonTable.reactionColors) do
    addonTable.colorMixins.reactionColors[reaction] = {}
    addonTable.colorMixins.reactionColors[reaction].reactionColorStart = CreateColor(get_rgb(colorTable.reactionColorStart))
    addonTable.colorMixins.reactionColors[reaction].reactionColorEnd = CreateColor(get_rgb(colorTable.reactionColorEnd))
  end
  -- Power
  addonTable.powerColors = CopyTable(self.db.profile.addonColors.powerColors)
  addonTable.colorMixins.powerColors = {}
  for power, colorTable in pairs(addonTable.powerColors) do
    addonTable.colorMixins.powerColors[power] = {}
    addonTable.colorMixins.powerColors[power].powerColorStart = CreateColor(get_rgb(colorTable.powerColorStart))
    addonTable.colorMixins.powerColors[power].powerColorEnd = CreateColor(get_rgb(colorTable.powerColorEnd))
  end
  -- Debuff
  addonTable.debuffColors = CopyTable(self.db.profile.addonColors.debuffColors)
  addonTable.colorMixins.debuffColors = {}
  for debuff, colorTable in pairs(addonTable.debuffColors) do
    addonTable.colorMixins.debuffColors[debuff] = {}
    addonTable.colorMixins.debuffColors[debuff].debuffColorStart = CreateColor(get_rgb(colorTable.debuffColorStart))
    addonTable.colorMixins.debuffColors[debuff].debuffColorEnd = CreateColor(get_rgb(colorTable.debuffColorEnd))
  end
  -- Health
  addonTable.healthColors = CopyTable(self.db.profile.addonColors.healthColors)
end
