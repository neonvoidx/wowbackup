local _, addonTable = ...
local addon = addonTable.addon

-- @TODO: Implement caching.

---Interpolate between two colors.
---@param color1 table {r,g,b} the colot to go to.
---@param color2 table {r,g,b} the color coming from.
---@param t number percentage, normalized to a range of 0 to 1
local function lerpColor(color1, color2, t)
  local r = color1["r"] * (1 - t) + color2["r"] * t
  local g = color1["g"] * (1 - t) + color2["g"] * t
  local b = color1["b"] * (1 - t) + color2["b"] * t
  return r, g, b
end

function addon:GetHealthValueColor(percentHealth)
  local color1, color2, t
  if percentHealth > 0.5 then
    -- Normalize percentHealth for the range 0.5 to 1
    t = (percentHealth - 0.5) / 0.5
    color1 = addonTable.healthColors.HIT_POINT.midHealth
    color2 = addonTable.healthColors.HIT_POINT.maxHealth
  else
    -- Normalize percentHealth for the range 0 to 0.5
    t = percentHealth / 0.5
    color1 = addonTable.healthColors.HIT_POINT.lowHealth
    color2 = addonTable.healthColors.HIT_POINT.midHealth
  end
  return lerpColor(color1, color2, t)
end
