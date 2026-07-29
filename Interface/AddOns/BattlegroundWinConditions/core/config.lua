local AddonName, NS = ...

local select = select
local UnitClass = UnitClass
local GetClassColor = GetClassColor
local CreateFrame = CreateFrame
local GetPlayerFactionGroup = GetPlayerFactionGroup

---@class PositionArray
---@field[1] string
---@field[2] string
---@field[3] number
---@field[4] number

---@class ColorArray
---@field r number
---@field g number
---@field b number
---@field a number

---@class BannerTable : table
---@field bannerfont string
---@field bannerscale number
---@field tiebgcolor ColorArray
---@field tietextcolor ColorArray
---@field winbgcolor ColorArray
---@field wintextcolor ColorArray
---@field losebgcolor ColorArray
---@field losetextcolor ColorArray
---@field resetbgcolor ColorArray
---@field resettextcolor ColorArray

---@class InfoTable : table
---@field infofont string
---@field infofontsize number
---@field infobg boolean
---@field infobgcolor ColorArray

---@class GeneralTable : table
---@field version number
---@field lock boolean
---@field test boolean
---@field banner boolean
---@field bannergroup BannerTable
---@field infogroup InfoTable

---@class MapTable : table
---@field enabled boolean

---@class TOKTable : table
---@field enabled boolean
---@field showorbinfo boolean
---@field showbuffinfo boolean

---@class EOTSTable : table
---@field enabled boolean
---@field showflaginfo boolean

---@class MapsTable : table
---@field arathibasin MapTable
---@field deepwindgorge MapTable
---@field eyeofthestorm EOTSTable
---@field silvershardmines MapTable
---@field deephaulravine MapTable
---@field templeofkotmogu TOKTable
---@field thebattleforgilneas MapTable
---@field twinpeaks MapTable
---@field warsonggulch MapTable

---@class GlobalTable : table
---@field general GeneralTable
---@field maps MapsTable
---@field position PositionArray
---@field lastFlagCapBy string
---@field debug boolean

---@class DBTable : table
---@field lastReadVersion string
---@field onlyShowWhenNewVersion boolean
---@field global GlobalTable

---@class BGWC
---@field ADDON_LOADED function
---@field PLAYER_LOGIN function
---@field UPDATE_UI_WIDGET function
---@field LOADING_SCREEN_DISABLED function
---@field PLAYER_LEAVING_WORLD function
---@field PLAYER_ENTERING_WORLD function
---@field PVP_MATCH_COMPLETE function
---@field PLAYER_JOINED_PVP_MATCH function
---@field UNIT_AURA function
---@field ARENA_OPPONENT_UPDATE function
---@field CHAT_MSG_ADDON function
---@field CHAT_MSG_BG_SYSTEM_ALLIANCE function
---@field CHAT_MSG_BG_SYSTEM_HORDE function
---@field CHAT_MSG_BG_SYSTEM_NEUTRAL function
---@field Init function
---@field Shutdown function
---@field SlashCommands function
---@field frame Frame
---@field db GlobalTable
---@field isInitialized boolean

---@type BGWC
---@diagnostic disable-next-line: missing-fields
local BGWC = {}
NS.BGWC = BGWC

local BGWCFrame = CreateFrame("Frame", AddonName .. "Frame")
BGWCFrame:SetScript("OnEvent", function(_, event, ...)
  if BGWC[event] then
    BGWC[event](BGWC, ...)
  end
end)
NS.BGWC.frame = BGWCFrame

-- Convert English faction to localized name (helpers.lua not loaded yet)
local initFaction = GetPlayerFactionGroup()
NS.PLAYER_FACTION = (initFaction == "Horde") and FACTION_HORDE or FACTION_ALLIANCE
NS.ALLIANCE_NAME = FACTION_ALLIANCE
NS.HORDE_NAME = FACTION_HORDE
NS.WIN_NOUN = "You"
NS.LOSE_NOUN = "They"
NS.ACTIVE_BASE_COUNT = 0
NS.INCOMING_BASE_COUNT = 0
NS.WIN_INC_BASE_COUNT = 0
NS.CURRENT_STACKS = 0
NS.DEFAULT_ORB_BUFF_TIME = 45
NS.DEFAULT_STACK_TIME = 30 -- blitz = 15
NS.DEFAULT_GROUP_SIZE = 10
NS.MIN_GROUP_SIZE = 8
NS.BASE_TIMER_EXPIRED = false
NS.STACKS_COUNTING = false
NS.HAS_FLAG_CARRIER = false
NS.IN_GAME = false
NS.IS_TEMPLE = false
NS.IS_EOTS = false
NS.IS_SSM = false
NS.IS_TP = false
NS.IS_WG = false
NS.IS_BLITZ = false

NS.userClass = select(2, UnitClass("player"))
NS.userClassHexColor = "|c" .. select(4, GetClassColor(NS.userClass))

NS.ADDON_PREFIX = "BGWC_VERSION"
NS.FoundNewVersion = false
NS.VERSION = 984

NS.DefaultDatabase = {
  lastReadVersion = "9.8.3",
  onlyShowWhenNewVersion = true,
  global = {
    general = {
      lock = false,
      banner = false,
      info = false,
      test = false,
      bannergroup = {
        bannerfont = "Friz Quadrata TT",
        bannerscale = 1,
        tiebgcolor = {
          r = 0 / 255,
          g = 0 / 255,
          b = 0 / 255,
          a = 1,
        },
        tietextcolor = {
          r = 255 / 255,
          g = 255 / 255,
          b = 255 / 255,
          a = 1,
        },
        winbgcolor = {
          r = 36 / 255,
          g = 126 / 255,
          b = 36 / 255,
          a = 1,
        },
        wintextcolor = {
          r = 255 / 255,
          g = 255 / 255,
          b = 255 / 255,
          a = 1,
        },
        losebgcolor = {
          r = 175 / 255,
          g = 34 / 255,
          b = 47 / 255,
          a = 1,
        },
        losetextcolor = {
          r = 255 / 255,
          g = 255 / 255,
          b = 255 / 255,
          a = 1,
        },
        resetbgcolor = {
          r = 119 / 255,
          g = 119 / 255,
          b = 119 / 255,
          a = 1,
        },
        resettextcolor = {
          r = 255 / 255,
          g = 255 / 255,
          b = 255 / 255,
          a = 1,
        },
      },
      infogroup = {
        infofont = "Friz Quadrata TT",
        infofontsize = 12,
        infotextcolor = {
          r = 255 / 255,
          g = 255 / 255,
          b = 255 / 255,
          a = 1,
        },
        infobg = false,
        infobgcolor = {
          r = 0 / 255,
          g = 0 / 255,
          b = 0 / 255,
          a = 0.5,
        },
      },
    },
    maps = {
      arathibasin = {
        enabled = true,
      },
      deepwindgorge = {
        enabled = true,
      },
      eyeofthestorm = {
        enabled = true,
        showflaginfo = true,
        showflagvalue = true,
      },
      silvershardmines = {
        enabled = false,
      },
      deephaulravine = {
        enabled = false,
      },
      templeofkotmogu = {
        enabled = true,
        showorbinfo = true,
        showbuffinfo = true,
      },
      thebattleforgilneas = {
        enabled = true,
      },
      twinpeaks = {
        enabled = true,
        showdebuffinfo = true,
      },
      warsonggulch = {
        enabled = true,
        showdebuffinfo = true,
      },
    },
    position = {
      "CENTER",
      "CENTER",
      0,
      0,
    },
    lastFlagCapBy = "",
    lastFlagStackInfo = nil,
    lastOrbStackInfo = nil,
    version = NS.VERSION,
    debug = false,
  },
}

--[[
-- Warsong Gulch
-- Instance ID: 2106
-- Zone ID: 1339
-- Arathi Basin
-- Instance ID: 2107
-- Zone ID: 1366
-- Eye of the Storm
-- Instance ID: 566
-- Zone ID: 112
-- The Battle for Gilneas
-- Instance ID: 761
-- Zone ID: 275
-- Twin Peaks
-- Instance ID: 726
-- Zone ID: 206
-- Silvershard Mines
-- Instance ID: 727
-- Zone ID: 423
-- Temple of Kotmogu
-- Instance ID: 998
-- Zone ID: 417
-- Deepwind Gorge
-- Instance ID: 2245
-- Zone ID: 1576
-- Seething Shore
-- Instance ID: 1803
-- Zone ID: 907
-- Deephaul Ravine
-- Instance ID: 2656
-- Zone ID: 2345
--]]
