local _, NS = ...

local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local strsplit = strsplit
local tonumber = tonumber

local sformat = string.format

local RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo.SendAddonMessage

local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

---@type BGWC
local BGWC = NS.BGWC
local BGWCFrame = NS.BGWC.frame

local Version = {}
NS.Version = Version

function Version:SendVersion()
  local channel

  if IsInRaid() then
    channel = (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT"
      or "RAID"
  elseif IsInGroup() then
    channel = (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT"
      or "PARTY"
  elseif IsInGuild() then
    channel = "GUILD"
  end

  if channel then
    SendAddonMessage(NS.ADDON_PREFIX, "Version;" .. NS.VERSION, channel)
  end
end

function Version:CheckVersion(text)
  local textEx = { strsplit(";", text) }

  if textEx[1] == "Version" then
    if not NS.FoundNewVersion and tonumber(textEx[2]) > NS.VERSION then
      local message = sformat("New version released!")
      NS.write(message)
      NS.FoundNewVersion = true
    end
  end
end

function BGWC:CHAT_MSG_ADDON(prefix, text, _, sender)
  if sender == NS.userNameWithRealm then
    return
  end

  if prefix == NS.ADDON_PREFIX then
    Version:CheckVersion(text)
  end
end

function Version:Setup()
  RegisterAddonMessagePrefix(NS.ADDON_PREFIX)
  BGWCFrame:RegisterEvent("CHAT_MSG_ADDON")
end
