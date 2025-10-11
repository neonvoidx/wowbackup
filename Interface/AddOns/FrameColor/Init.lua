local addonName, private = ...

-- Create a global table named the same as the addonName.
_G[addonName] = {} -- Other files will refer to this as global.

-- Setup the private table structure.

-- Information about the player character.
private.playerInfo = {
  class = select(2, UnitClass("player"))
}

-- Addon Mixins.
private.mixins = {}

-- Addon colors.
private.colors = {
  defaultColor = {0.2, 0.2, 0.2, 1},
  default = {
    main = {0.28, 0.28, 0.28, 1},
    background = {0.55, 0.55, 0.55, 1},
    borders = {0.2, 0.2, 0.2, 1},
    controls = {0.5, 0.5, 0.5, 1},
    tabs = {0.18, 0.18, 0.18, 1},
    fallback = {0.22, 0.22, 0.22, 1},
  }
}

