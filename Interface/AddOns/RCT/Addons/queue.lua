local addonName, _ = ...
local L = _G.RCT_LOCALE or {}
local RCT = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)
if not RCT then return end

local AceComm = LibStub("AceComm-3.0")
local COMM_PREFIX = "RCTQ"

-- Spam protection
local lastAnnounce = {}
local COOLDOWN = 180 -- 3 min

-- Announce with RW/Party/Print, spam-protected
local function AnnouncePlayer(name, queueType)
    -- only announce if you're the group leader
    local _, instType = IsInInstance()
    if instType == "pvp" then
        return
    end
    if IsInGroup() and not UnitIsGroupLeader("player") then
        return
    end

    local now = GetTime()
    if lastAnnounce[name] and (now - lastAnnounce[name]) < COOLDOWN then
        return
    end
    lastAnnounce[name] = now

    local msg = string.format("%s is in queue (%s).", name, queueType or "unknown")

    if IsInRaid() then
        if UnitIsGroupLeader("player") then
            SendChatMessage(msg, "RAID_WARNING")
        else
            RCT:Print("|cffff0000[HatedGaming Snitch]|r "..msg.." (no RW permission).")
        end
    elseif IsInGroup() then
        SendChatMessage(msg, "PARTY")
    else
        RCT:Print("|cffff0000[HatedGaming Snitch]|r "..msg)
    end
end

-- Handle incoming addon messages
function RCT:HandleQueueMessage(msg, sender)
    -- disable in battlegrounds or arenas
    local inInstance, instType = IsInInstance()
    if instType == "pvp" then
        return
    end
    if not sender or sender == UnitName("player") then return end
    local parts = { strsplit(":", msg) }
    if parts[1] == "QUEUED" then
        AnnouncePlayer(sender, parts[2])
    end
end

-- Broadcast your own queue state
local function BroadcastMyQueue()
if not (IsInGroup() or IsInRaid()) then
    return
end
    local inInstance, instType = IsInInstance()
    if instType == "pvp" then
        return
    end
    -- BG / Arena

    for i = 1, GetMaxBattlefieldID() do
        local status = GetBattlefieldStatus(i)
        if status == "queued" then
            C_ChatInfo.SendAddonMessage(COMM_PREFIX, "QUEUED:BG", IsInRaid() and "RAID" or "PARTY")
            return
        end
    end

    -- LFG (dungeons/raids/scenarios)
    local mode, submode = nil, nil
    do
        local success, m, sm = pcall(GetLFGMode)
        if success then
            mode, submode = m, sm
        end
    end
    if mode == "queued" then
        C_ChatInfo.SendAddonMessage(COMM_PREFIX, "QUEUED:LFG", IsInRaid() and "RAID" or "PARTY")
        return
    end
end

-- Enable snitch
function RCT:EnableQueueSnitch()
    -- Register comms
    AceComm:RegisterComm(COMM_PREFIX, function(_, msg, _, sender)
        self:HandleQueueMessage(msg, Ambiguate(sender, "short"))
    end)

    -- Watch your own queue events
    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    f:RegisterEvent("LFG_UPDATE")
    f:SetScript("OnEvent", function()
        BroadcastMyQueue()
    end)
end

-- Activate on load
RCT:EnableQueueSnitch()
