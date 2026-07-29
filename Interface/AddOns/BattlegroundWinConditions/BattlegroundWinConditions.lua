local _, NS = ...

local IsInInstance = IsInInstance

local GetActiveMatchState = C_PvP.GetActiveMatchState

---@type BGWC
local BGWC = NS.BGWC
local BGWCFrame = BGWC.frame

local Maps = NS.Maps
local Interface = NS.Interface

local INIT_EVENTS = {
  "PLAYER_ENTERING_WORLD",
  "PLAYER_JOINED_PVP_MATCH",
}

local ACTIVE_EVENTS = {
  "PLAYER_LEAVING_WORLD",
  "PVP_MATCH_COMPLETE",
}

function BGWC:Init()
  if self.isInitialized then
    return
  end
  self.isInitialized = true

  FrameUtil.RegisterFrameForEvents(BGWCFrame, ACTIVE_EVENTS)

  Interface:Clear()
  Maps:PrepareZone()
end

function BGWC:Shutdown()
  FrameUtil.UnregisterFrameForEvents(BGWCFrame, ACTIVE_EVENTS)

  self.isInitialized = false

  Interface:Clear()
  Maps:DisableZone()
end

local function HandleMatchEnd()
  local isInInstance = IsInInstance()
  if GetActiveMatchState() >= Enum.PvPMatchState.PostRound or isInInstance == false then
    BGWC:Shutdown()
  end
end

-- The "PLAYER_LEAVING_WORLD" and "PLAYER_LOGOUT" events both fire on a ui reload so addons can shut down cleanly before being reloaded
-- https://www.reddit.com/r/wowaddons/comments/92ch0u/comment/e34zj4j/
function BGWC:PLAYER_LEAVING_WORLD()
  HandleMatchEnd()
end

function BGWC:PVP_MATCH_COMPLETE()
  HandleMatchEnd()
end

-- 0 = Inactive
-- 1 = Waiting
-- 2 = StartUp
-- 3 = Engaged
-- 4 = PostRound
-- 5 = Complete
function BGWC:PLAYER_ENTERING_WORLD()
  local matchState = GetActiveMatchState()
  if matchState > Enum.PvPMatchState.Waiting and matchState < Enum.PvPMatchState.PostRound then
    self:Init()
  elseif matchState == Enum.PvPMatchState.Inactive then
    local _, instanceType = IsInInstance()

    NS.PLAYER_FACTION = NS.GetLocalizedFaction(GetPlayerFactionGroup())
    NS.IN_GAME = false
    NS.IS_BLITZ = false

    if instanceType ~= "pvp" and instanceType ~= "none" then
      Interface:Clear()
      return
    end

    Interface:Start()
  end
end

function BGWC:PLAYER_JOINED_PVP_MATCH()
  local matchState = GetActiveMatchState()
  if matchState >= Enum.PvPMatchState.Waiting and matchState <= Enum.PvPMatchState.Engaged then
    self:Init()
  end
end

function BGWC:PLAYER_LOGIN()
  BGWCFrame:UnregisterEvent("PLAYER_LOGIN")

  NS.userNameWithRealm = NS.GetUnitNameAndRealm("player")

  Interface:Create()

  FrameUtil.RegisterFrameForEvents(BGWCFrame, INIT_EVENTS)
end
BGWCFrame:RegisterEvent("PLAYER_LOGIN")
