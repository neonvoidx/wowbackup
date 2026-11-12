local _, private = ...

-- Specify the options.
local options = {
  name = "_CompactRaidGroup",
  displayedName = "",
  order = 10,
  category = "UnitFrames",
  colors = {
    ["main"] = {
      order = 1,
      name = "",
      rgbaValues = private.colors.default.main,
    },
  },
}

local function skinRaidFrameBorder(RAID_GROUP, color)
  for _, texture in pairs({
    _G["CompactRaidGroup" ..RAID_GROUP.. "BorderFrameBorderLeft"],
    _G["CompactRaidGroup" ..RAID_GROUP.. "BorderFrameBorderRight"],
    _G["CompactRaidGroup" ..RAID_GROUP.. "BorderFrameBorderTop"],
    _G["CompactRaidGroup" ..RAID_GROUP.. "BorderFrameBorderBottom"],
    _G["CompactRaidGroup" ..RAID_GROUP.. "BorderFrameBorderTopRight"],
    _G["CompactRaidGroup" ..RAID_GROUP.. "BorderFrameBorderBottomRight"],
    _G["CompactRaidGroup" ..RAID_GROUP.. "BorderFrameBorderTopLeft"],
    _G["CompactRaidGroup" ..RAID_GROUP.. "BorderFrameBorderBottomLeft"],
  }) do
    texture:SetVertexColor(color[1], color[2], color[3], color[4])
  end
  for n=1,5 do
    for _, texture in pairs({
      _G["CompactRaidGroup"..RAID_GROUP.. "Member" ..n.. "HorizBottomBorder"],
      _G["CompactRaidGroup"..RAID_GROUP.. "Member" ..n.. "HorizTopBorder"],
      _G["CompactRaidGroup"..RAID_GROUP.. "Member" ..n.. "VertRightBorder"],
      _G["CompactRaidGroup"..RAID_GROUP.. "Member" ..n.. "VertLeftBorder"],
    }) do
      texture:SetVertexColor(color[1], color[2], color[3], color[4])
    end
  end
end

-- Register the Skin
local skin = private:RegisterSkin(options)

local counter = 0 -- The raid group borders are created on demand.

function skin:OnEnable()
  local mainColor = self:GetColor("main")

  self:HookFunc("CompactRaidGroup_OnLoad",function()
    counter = counter + 1

    skinRaidFrameBorder(counter, mainColor)

    if counter == 8 then -- There is a total of 8 containers.
      self:Unhook("CompactRaidGroup_OnLoad")
    end
  end)

  skin:Apply(mainColor)
end

function skin:OnDisable()
  self:Apply({1,1,1,1})
end

function skin:Apply(color)
  for i=1, NUM_RAID_GROUPS do
    skinRaidFrameBorder(i, color)
  end
end


