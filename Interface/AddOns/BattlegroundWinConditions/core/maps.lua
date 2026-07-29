local _, NS = ...

local next = next
local select = select
local IsInInstance = IsInInstance
local GetInstanceInfo = GetInstanceInfo
-- local GetNumGroupMembers = GetNumGroupMembers

local After = C_Timer.After
-- local IsSoloRBG = C_PvP.IsSoloRBG

local Interface = NS.Interface
local Version = NS.Version

local Maps = {}
NS.Maps = Maps

do
  local prevZone = 0
  local zoneIds = {}

  function Maps:RegisterZone(instanceID)
    zoneIds[instanceID] = self
  end

  function Maps:DisableZone()
    if zoneIds[prevZone] then
      zoneIds[prevZone]:ExitZone()
      prevZone = 0
    end
  end

  function Maps:EnableZone(instanceID, isBlitz)
    NS.PLAYER_FACTION = NS.GetLocalizedFaction(GetPlayerFactionGroup())
    NS.IN_GAME = true
    NS.IS_BLITZ = NS.isBlitz()

    prevZone = instanceID
    zoneIds[instanceID]:EnterZone(instanceID, isBlitz)

    Version:SendVersion()

    -- SELECTED_CHAT_FRAME:Clear()
  end

  local function checkMaxPlayers(instanceID)
    local function checkPlayers()
      local maxPlayers = select(5, GetInstanceInfo())

      if maxPlayers == 0 then
        After(1, checkPlayers)
      else
        local isBlitz = NS.isBlitz()

        Maps:EnableZone(instanceID, isBlitz)
      end
    end

    checkPlayers()
  end

  function Maps:PrepareZone()
    if IsInInstance() then
      local instanceID = select(8, GetInstanceInfo())
      if zoneIds[instanceID] then
        checkMaxPlayers(instanceID)
      else
        Interface:Clear()
      end
    else
      NS.PLAYER_FACTION = NS.GetLocalizedFaction(GetPlayerFactionGroup())
      NS.IN_GAME = false
      NS.IS_BLITZ = false

      Interface:Start()
    end
  end
end

function Maps:NewMod()
  local t = {}
  for k, v in next, Maps do
    t[k] = v
  end
  return t
end
