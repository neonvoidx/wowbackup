-- Setup the defaults that will be registered to AceDB.
local addonName, private = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local defaults = {
  profile = {
    protected = {
      leadingColors = {
        global = {
          order = 1,
          name = L["global_color"],
          enabled = false,
          colors = {
            ["main"] = {
              order = 1,
              name = L["the_one_color"],
              rgbaValues = private.colors.default.main,
            },
          },
        },
        UnitFrames = {
          order = 2,
          name = L["unit_frames"],
          enabled = false,
          colors = {
            ["main"] = {
              order = 1,
              name = L["main"],
              rgbaValues = {0.2, 0.2, 0.2, 1},
            },
            ["fallback"] = {
              order = 2,
              name = L["fallback"],
              rgbaValues = {0 ,0 ,0, 1},
            },
          },
        },
        HUD = {
          order = 3,
          name = L["hud"],
          enabled = false,
          colors = {
            ["main"] = {
              order = 1,
              name = L["main"],
              rgbaValues = private.colors.default.main,
            },
            ["background"] = {
              order = 2,
              name = L["background"],
              rgbaValues = private.colors.default.background,
            },
            ["borders"] = {
              order = 3,
              name = L["borders"],
              rgbaValues = private.colors.default.borders,
            },
            ["controls"] = {
              order = 4,
              name = L["controls"],
              rgbaValues = private.colors.default.controls,
            },
            ["tabs"] = {
              order = 5,
              name = L["tabs"],
              rgbaValues = private.colors.default.tabs,
            },
            ["fallback"] = {
              order = 6,
              name = L["fallback"],
              rgbaValues = private.colors.default.fallback,
            },
          },
        },
        MicroMenu = {
          order = 4,
          name = L["micro_menu"],
          enabled = false,
          colors = {
            ["btn_normal_color"] = {
              order = 1,
              name = L["btn_normal_color"],
              rgbaValues = private.colors.default.main,
            },
            ["btn_highlight_color"] = {
              order = 2,
              name = L["btn_highlight_color"],
              rgbaValues = {1, 1, 1, 1},
            },
            ["btn_pushed_color"] = {
              order = 3,
              name = L["btn_pushed_color"],
              rgbaValues = private.colors.default.main,
            },
          },
        },
        ActionBars = {
          order = 5,
          name = L["action_bars"],
          enabled = false,
          colors = {
            ["main"] = {
              order = 1,
              name = L["main"],
              rgbaValues = {0 ,0 ,0, 1},
            },
          },
        },
        Windows = {
          order = 6,
          name = L["windows"],
          enabled = false,
          colors = {
            ["main"] = {
              order = 1,
              name = L["main"],
              rgbaValues = private.colors.default.main,
            },
            ["background"] = {
              order = 2,
              name = L["background"],
              rgbaValues = private.colors.default.background,
            },
            ["borders"] = {
              order = 3,
              name = L["borders"],
              rgbaValues = private.colors.default.borders,
            },
            ["controls"] = {
              order = 4,
              name = L["controls"],
              rgbaValues = private.colors.default.controls,
            },
            ["tabs"] = {
              order = 5,
              name = L["tabs"],
              rgbaValues = private.colors.default.tabs,
            },
            ["fallback"] = {
              order = 6,
              name = L["fallback"],
              rgbaValues = private.colors.default.fallback,
            },
          },
        },
        AddonSkins = {
          order = 7,
          name = L["addon_skins"],
          enabled = false,
          colors = {
            ["main"] = {
              order = 1,
              name = L["main"],
              rgbaValues = private.colors.default.main,
            },
            ["background"] = {
              order = 2,
              name = L["background"],
              rgbaValues = private.colors.default.background,
            },
            ["borders"] = {
              order = 3,
              name = L["borders"],
              rgbaValues = private.colors.default.borders,
            },
            ["controls"] = {
              order = 4,
              name = L["controls"],
              rgbaValues = private.colors.default.controls,
            },
            ["tabs"] = {
              order = 5,
              name = L["tabs"],
              rgbaValues = private.colors.default.tabs,
            },
            ["fallback"] = {
              order = 6,
              name = L["fallback"],
              rgbaValues = private.colors.default.fallback,
            },
          },
        },
      },
    },
  },
  global = {
    ClassColors = {
      DEATHKNIGHT   = {0.77, 0.12, 0.23, 1},
      DEMONHUNTER   = {0.64, 0.19, 0.79, 1},
      DRUID         = {1.00, 0.49, 0.04, 1},
      EVOKER        = {0.20, 0.58, 0.50, 1},
      HUNTER        = {0.67, 0.83, 0.45, 1},
      MAGE          = {0.25, 0.78, 0.92, 1},
      MONK          = {0.00, 1.00, 0.60, 1},
      PALADIN       = {0.96, 0.55, 0.73, 1},
      PRIEST        = {1.00, 1.00, 1.00, 1},
      ROGUE         = {1.00, 0.96, 0.41, 1},
      SHAMAN        = {0.00, 0.44, 0.87, 1},
      WARLOCK       = {0.53, 0.53, 0.90, 1},
      WARRIOR       = {0.78, 0.61, 0.43, 1},
    },
    ReactionColors = {
      [2] = {1, 0, 0, 1}, -- Hostile
      [4] = {1, 1, 0, 1}, -- Neutral
      [5] = {0, 1, 0, 1}, -- Friendly
    }
  },
}

function private.RegisterModuleDefaults(moduleOptions)
  defaults.profile[moduleOptions.name] = moduleOptions
end

function private.GetModuleDefaults(moduleName)
  return defaults.profile[moduleName] and CopyTable(defaults.profile[moduleName]) or nil
end

function private.GetDefaults()
  return defaults
end
