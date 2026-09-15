-- comm.lua: WarGames+ Arena Stats Sync + V2 Ban Protocol
-- Broadcasts challenge metadata so all addon users in the match can record results.
-- Sends to: party (teammates), whisper (opponent), and opponent relays to their party.
-- V2 protocol: PING/PONG addon detection, BAN_INIT/BAN_PICK/BAN_RESULT for map bans.

local WG = _G["WargamesPlus"]
if not WG then return end
local L = WG.L

local PREFIX    = "WGPlus"

C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

-- ---------- ADDON USER TRACKING ----------
WG.addonUsers = WG.addonUsers or {}  -- keyed by short character name → timestamp
WG.addonUserRealms = WG.addonUserRealms or {}  -- short name → normalized realm we last saw them on
WG._lastPingTime = WG._lastPingTime or {}  -- rate-limit pings per target
WG._matchGeneration = WG._matchGeneration or 0  -- incremented per match; scopes the 300s safety-net timer

-- ---------- BAN STATE ----------
WG.banState = nil  -- nil | "selecting" | "waiting" | "complete"
WG._banData = nil  -- { opponent, mapPool, maxBans, myBans, theirBans, initiator }

-- ---------- SERIALIZATION (legacy V1) ----------
local function Serialize(challenge)
    return table.concat({
        challenge.opponent or "",
        challenge.map or "",
        challenge.mode or "",
        challenge.matchSize or "",
        tostring(challenge.timestamp or 0),
        challenge.initiator or "",
    }, "\t")
end

local function Deserialize(msg)
    local parts = {}
    for part in msg:gmatch("([^\t]*)") do
        table.insert(parts, part)
    end
    -- gmatch("([^\t]*)") produces an extra empty string at the end; remove it
    if parts[#parts] == "" then table.remove(parts) end
    if #parts < 5 then return nil end
    local timestamp = tonumber(parts[5])
    if not timestamp then return nil end
    return {
        opponent  = parts[1],
        map       = parts[2],
        mode      = parts[3],
        matchSize = parts[4],
        timestamp = timestamp,
        initiator = parts[6] or nil,
    }
end

-- ---------- CHANNEL HELPER ----------
local function GetChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        return "PARTY"
    end
    return nil
end

-- True if the player is inside an arena/BG instance. Used to skip
-- SendAddonMessage calls — Blizzard blocks addon comms in-instance as of 12.0.5.
local function IsWargameInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "arena" or instanceType == "pvp")
end
WG.IsWargameInstance = IsWargameInstance

-- ---------- V2 MESSAGE HELPERS ----------
-- Addon messages are hard-capped at 255 bytes by the client; anything longer is
-- silently dropped. Large V2 payloads (e.g. a VETO_INVITE carrying the full arena
-- map pool) are split into "V2C:" chunk frames and reassembled on the far side
-- (see ReassembleChunk / OnAddonMessage). Short payloads take the byte-identical
-- pre-chunking path.
local MAX_ADDON_MSG = 240
local CHUNK_BODY    = MAX_ADDON_MSG - 24  -- room for the "V2C:id|seq|total|" header
local chunkSeqId    = 0

local function RawSend(payload, ...)
    if #payload <= MAX_ADDON_MSG then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, ...)
        return
    end
    chunkSeqId = chunkSeqId + 1
    local id = chunkSeqId
    local total = math.ceil(#payload / CHUNK_BODY)
    for i = 1, total do
        local body = payload:sub((i - 1) * CHUNK_BODY + 1, i * CHUNK_BODY)
        C_ChatInfo.SendAddonMessage(PREFIX, "V2C:" .. id .. "|" .. i .. "|" .. total .. "|" .. body, ...)
    end
end

local function SendV2(msgType, target, ...)
    local parts = {select(1, ...)}
    local payload = "V2:" .. msgType .. "\t" .. table.concat(parts, "\t")
    RawSend(payload, "WHISPER", target)
end

local function SendV2Party(msgType, ...)
    local parts = {select(1, ...)}
    local payload = "V2:" .. msgType .. "\t" .. table.concat(parts, "\t")
    local ch = GetChannel()
    if ch then
        RawSend(payload, ch)
    end
end

-- Chunk reassembly buffer, keyed by "<sender>\30<id>". Returns the full payload
-- string once every chunk has arrived, nil otherwise. Partial sets older than
-- 30s are dropped so a lost chunk can't leak the buffer.
local chunkBuf = {}
local function ReassembleChunk(sender, msg)
    local id, seq, total, body = msg:match("^V2C:(%d+)|(%d+)|(%d+)|(.*)$")
    if not id then return nil end
    seq, total = tonumber(seq), tonumber(total)
    if not seq or not total or seq < 1 or seq > total then return nil end

    local now = GetTime()
    for k, b in pairs(chunkBuf) do
        if now - b.t > 30 then chunkBuf[k] = nil end
    end

    local key = sender .. "\30" .. id
    local buf = chunkBuf[key]
    if not buf then
        buf = { parts = {}, count = 0, total = total, t = now }
        chunkBuf[key] = buf
    end
    if not buf.parts[seq] then
        buf.parts[seq] = body
        buf.count = buf.count + 1
    end
    if buf.count < buf.total then return nil end

    chunkBuf[key] = nil
    return table.concat(buf.parts)
end

local function ParseV2(msg)
    local msgType, rest = msg:match("^V2:(%u[%u_]*)%\t?(.*)")
    if not msgType then return nil, nil end
    return msgType, rest
end

-- ---------- NAME / REALM RESOLUTION ----------
-- The local player's realm, normalized the way whisper targets want it
-- (no spaces or punctuation, e.g. "Aerie Peak" -> "AeriePeak").
local function LocalRealmSuffix()
    local r = (GetNormalizedRealmName and GetNormalizedRealmName())
        or (GetRealmName and GetRealmName()) or ""
    return (r:gsub("[%s'%-]", ""))
end
WG.LocalRealmSuffix = LocalRealmSuffix

-- Turn anything the user typed or we received into a whisper-safe target:
--   "Name#1234"  -> resolved online character name, or nil if unresolvable
--   "Name"       -> "Name-<realm>" (a realm we've seen them on, else our own)
--   "Name-Realm" -> "Name-Realm" (realm punctuation/spaces stripped)
-- Bare names are always realm-qualified because C_ChatInfo.SendAddonMessage
-- "WHISPER" silently fails to reach a connected-realm character otherwise.
function WG.ResolveWhisperName(name)
    if not name or name == "" then return nil end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")

    if name:find("#") then
        local resolved = WG.ResolveBTagToCharName and WG.ResolveBTagToCharName(name)
        if not resolved or resolved == "" then return nil end
        name = resolved
    end

    local base, realm = name:match("^(.-)%-(.+)$")
    if base and base ~= "" then
        return base .. "-" .. (realm:gsub("[%s']", ""))
    end

    local seen = WG.addonUserRealms and WG.addonUserRealms[name]
    if seen and seen ~= "" then
        return name .. "-" .. seen
    end
    return name .. "-" .. LocalRealmSuffix()
end

-- Short, realm-free character name — the form addonUsers / session matching use.
function WG.ShortName(name)
    if not name or name == "" then return name end
    return (name:gsub("^%s+", ""):gsub("%s+$", ""):match("^([^-#]+)")) or name
end

-- ---------- V2 HANDLERS ----------
local function HandlePing(sender, _, channel)
    -- Record that sender has the addon
    WG.addonUsers[sender] = time()
    -- Only reply via whisper if PING came via whisper
    -- Party members discover each other via broadcast (avoids "No player named" for cross-faction)
    if channel == "WHISPER" then
        -- Whisper back realm-qualified so the PONG reaches a connected-realm sender.
        SendV2("PONG", WG.ResolveWhisperName(sender) or sender, UnitName("player"))
    end
    -- Auto-refresh friend list so [WG+] indicator appears without manual refresh
    if WG.mainFrame and WG.mainFrame:IsShown() and WG.mainFrame.Refresh then
        WG.mainFrame:Refresh()
    end
end

local function HandlePong(sender, _, channel)
    -- Record that sender has the addon
    WG.addonUsers[sender] = time()
    -- Auto-refresh friend list so [WG+] indicator appears without manual refresh
    if WG.mainFrame and WG.mainFrame:IsShown() and WG.mainFrame.Refresh then
        WG.mainFrame:Refresh()
    end
end

local function HandleBanInit(sender, rest)
    -- Format: bansPerPlayer\tmap1\tmap2\t...
    local parts = {}
    for part in rest:gmatch("[^\t]+") do
        table.insert(parts, part)
    end
    if #parts < 2 then return end

    local maxBans = tonumber(parts[1]) or 2
    local mapPool = {}
    for i = 2, #parts do
        table.insert(mapPool, parts[i])
    end

    -- Record sender as having addon
    WG.addonUsers[sender] = time()

    -- Set up ban state as receiver
    WG.banState = "selecting"
    WG._banData = {
        opponent = sender,
        mapPool = mapPool,
        maxBans = maxBans,
        myBans = {},
        theirBans = nil,
        initiator = false,
    }

    -- Reply with PONG to confirm we have the addon
    SendV2("PONG", sender, UnitName("player"))

    print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. sender .. " started map ban phase. Select " .. maxBans .. " maps to ban.")

    -- Trigger UI refresh for ban mode
    if WG.mainFrame and WG.mainFrame.RefreshBanMode then
        WG.mainFrame:RefreshBanMode()
    end
end

local function ResolveBanResult()
    local bd = WG._banData
    if not bd or not bd.myBans or not bd.theirBans then return end

    -- Combine all bans
    local banned = {}
    for _, m in ipairs(bd.myBans) do banned[m] = true end
    for _, m in ipairs(bd.theirBans) do banned[m] = true end

    -- Filter map pool
    local remaining = {}
    for _, m in ipairs(bd.mapPool) do
        if not banned[m] then
            table.insert(remaining, m)
        end
    end

    if #remaining == 0 then
        -- All maps banned, use full pool
        remaining = bd.mapPool
    end

    local selected = remaining[math.random(1, #remaining)]

    -- If we are the initiator, send BAN_RESULT to opponent
    if bd.initiator then
        SendV2("BAN_RESULT", bd.opponent, selected)
    end

    WG.banState = "complete"
    print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["BAN_RESULT"], selected))

    -- Auto-fill map selection in UI
    if WG.mainFrame and WG.mainFrame.SelectMapByName then
        WG.mainFrame:SelectMapByName(selected)
    end

    -- Clean up ban state after a short delay
    C_Timer.After(2, function()
        WG.banState = nil
        WG._banData = nil
        if WG.mainFrame and WG.mainFrame.RefreshBanMode then
            WG.mainFrame:RefreshBanMode()
        end
    end)
end

local function HandleBanPick(sender, rest)
    -- Format: ban1\tban2
    local bans = {}
    for part in rest:gmatch("[^\t]+") do
        table.insert(bans, part)
    end

    if not WG._banData or WG._banData.opponent ~= sender then return end

    WG._banData.theirBans = bans
    WG.addonUsers[sender] = time()

    -- Only the initiator resolves; non-initiator waits for BAN_RESULT
    if WG._banData.initiator and WG._banData.myBans and #WG._banData.myBans > 0 then
        ResolveBanResult()
    elseif not WG._banData.initiator then
        -- Non-initiator: just note that opponent submitted, keep waiting for BAN_RESULT
        WG.banState = "waiting"
        print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["BAN_WAITING"])
        if WG.mainFrame and WG.mainFrame.RefreshBanMode then
            WG.mainFrame:RefreshBanMode()
        end
        -- Timeout: cancel if no BAN_RESULT received within 15 seconds
        C_Timer.After(15, function()
            if WG.banState == "waiting" then
                WG.banState = nil
                WG._banData = nil
                print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["BAN_CANCELLED"] .. " (timed out)")
                if WG.mainFrame and WG.mainFrame.RefreshBanMode then
                    WG.mainFrame:RefreshBanMode()
                end
            end
        end)
    else
        WG.banState = "selecting"
        print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["BAN_SUBMIT"] .. "!")
    end
end

local function HandleBanCancel(sender)
    if not WG._banData or WG._banData.opponent ~= sender then return end

    WG.banState = nil
    WG._banData = nil
    print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["BAN_CANCELLED"])
    if WG.mainFrame and WG.mainFrame.RefreshBanMode then
        WG.mainFrame:RefreshBanMode()
    end
end

local function HandleBanResult(sender, rest)
    -- Format: selectedMap
    local selected = rest:match("^([^\t]+)")
    if not selected then return end

    WG.banState = "complete"
    print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. string.format(L["BAN_RESULT"], selected))

    -- Auto-fill map selection
    if WG.mainFrame and WG.mainFrame.SelectMapByName then
        WG.mainFrame:SelectMapByName(selected)
    end

    -- Clean up
    C_Timer.After(2, function()
        WG.banState = nil
        WG._banData = nil
        if WG.mainFrame and WG.mainFrame.RefreshBanMode then
            WG.mainFrame:RefreshBanMode()
        end
    end)
end

local function HandleChallenge(sender, rest, channel)
    -- Challenge data: opponent\tmap\tmode\tmatchSize\ttimestamp\tinitiator
    -- ResolveOpponent (in tracker.lua) flips opponent/initiator at match end using scoreboard
    if WG.lastChallenge then return end -- don't overwrite active challenge

    local parts = {}
    for part in rest:gmatch("([^\t]*)") do table.insert(parts, part) end
    if parts[#parts] == "" then table.remove(parts) end
    if #parts < 5 then return end

    local ts = tonumber(parts[5])
    if not ts then return end

    local challenge = {
        opponent  = parts[1],
        map       = parts[2],
        mode      = parts[3],
        matchSize = parts[4],
        timestamp = ts,
        initiator = parts[6] or sender,
    }

    WG.lastChallenge = challenge
    WG_History.lastChallenge = challenge

    -- Relay to our own party so teammates also get tracking data
    -- Only relay whispers; party messages are already visible to the group
    -- Skip relay if we're already inside the wargame instance — 12.0.5 blocks it.
    if channel == "WHISPER" and not IsWargameInstance() then
        local ch = GetChannel()
        if ch then
            SendV2Party("CHALLENGE", parts[1], parts[2], parts[3],
                parts[4], tostring(ts), challenge.initiator)
        end
    end
end

local function HandleSyncRequest(sender, rest, channel)
    if channel ~= "PARTY" and channel ~= "INSTANCE_CHAT" then return end
    if IsWargameInstance() then return end
    -- Respond with cached winner if we have it
    if WG._lastMatchWinner ~= nil then
        SendV2Party("MATCH_SYNC", tostring(WG._lastMatchWinner))
    end
end

local function HandleMatchSync(sender, rest, channel)
    -- Only accept from party/instance channel, not whispers
    if channel ~= "PARTY" and channel ~= "INSTANCE_CHAT" then return end

    local parts = {}
    for part in rest:gmatch("[^\t]+") do
        table.insert(parts, part)
    end
    local winner = tonumber(parts[1])
    if winner == nil then return end

    -- Forward to tracker for processing
    if WG.OnMatchSyncReceived then
        WG.OnMatchSyncReceived(sender, winner)
    end
end

-- ---------- V2 MESSAGE ROUTER ----------
local V2_HANDLERS = {
    PING       = HandlePing,
    PONG       = HandlePong,
    BAN_INIT   = HandleBanInit,
    BAN_PICK   = HandleBanPick,
    BAN_CANCEL = HandleBanCancel,
    BAN_RESULT = HandleBanResult,
    CHALLENGE     = HandleChallenge,
    MATCH_SYNC    = HandleMatchSync,
    SYNC_REQUEST  = HandleSyncRequest,
    -- Veto system handlers (veto.lua registers these functions on WG)
    VETO_INVITE  = function(sender, rest) if WG.VetoOnInvite then WG.VetoOnInvite(sender, rest) end end,
    VETO_ACCEPT  = function(sender, rest) if WG.VetoOnAccept then WG.VetoOnAccept(sender) end end,
    VETO_DECLINE = function(sender, rest) if WG.VetoOnDecline then WG.VetoOnDecline(sender) end end,
    VETO_BAN     = function(sender, rest) if WG.VetoOnBan then WG.VetoOnBan(sender, rest) end end,
    VETO_PICK    = function(sender, rest) if WG.VetoOnPick then WG.VetoOnPick(sender, rest) end end,
    VETO_CANCEL  = function(sender, rest) if WG.VetoOnCancel then WG.VetoOnCancel(sender) end end,
    VETO_READY   = function(sender, rest) if WG.VetoOnReady then WG.VetoOnReady(sender) end end,
    -- Ready check handlers (readycheck.lua registers these functions on WG)
    RC_INIT   = function(sender, rest, channel) if WG.RCOnInit   then WG.RCOnInit(sender, rest) end end,
    RC_ACK    = function(sender, rest, channel) if WG.RCOnAck    then WG.RCOnAck(sender, rest) end end,
    RC_TEAM   = function(sender, rest, channel) if WG.RCOnTeam   then WG.RCOnTeam(sender, rest) end end,
    RC_STATE  = function(sender, rest, channel) if WG.RCOnState  then WG.RCOnState(sender, rest, channel) end end,
    RC_CANCEL = function(sender, rest, channel) if WG.RCOnCancel then WG.RCOnCancel(sender, rest) end end,
    -- Slaughterhouse handlers (slaughterhouse.lua registers these functions on WG)
    SH_INVITE  = function(sender, rest) if WG.SlaughterHouseOnInvite  then WG.SlaughterHouseOnInvite(sender, rest) end end,
    SH_ACCEPT  = function(sender, rest) if WG.SlaughterHouseOnAccept  then WG.SlaughterHouseOnAccept(sender, rest) end end,
    SH_DECLINE = function(sender, rest) if WG.SlaughterHouseOnDecline then WG.SlaughterHouseOnDecline(sender, rest) end end,
    SH_ORDER   = function(sender, rest) if WG.SlaughterHouseOnOrder   then WG.SlaughterHouseOnOrder(sender, rest) end end,
    SH_DECLARE = function(sender, rest) if WG.SlaughterHouseOnDeclare then WG.SlaughterHouseOnDeclare(sender, rest) end end,
    SH_CANCEL  = function(sender, rest) if WG.SlaughterHouseOnCancel  then WG.SlaughterHouseOnCancel(sender) end end,
}

-- ---------- BROADCAST (called from core.lua before StartWarGameByName) ----------
-- Must run BEFORE zone-in: as of WoW 12.0.5, addons cannot SendAddonMessage
-- while the player is inside an arena/BG instance.
function WG.BroadcastChallenge()
    if not WG.lastChallenge then return end
    local payload = Serialize(WG.lastChallenge)

    -- Send to own party (inviter's teammates)
    local channel = GetChannel()
    if channel then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, channel)
    end

    -- Whisper opponent via V2 CHALLENGE (sets their lastChallenge with correct opponent)
    local c = WG.lastChallenge
    local opponent = c.opponent
    if opponent and opponent ~= "" then
        SendV2("CHALLENGE", opponent,
            c.opponent, c.map or "", c.mode or "", c.matchSize or "",
            tostring(c.timestamp or 0), c.initiator or "")
    end
end

-- ---------- PUBLIC: PING for addon detection ----------
function WG.PingForAddon(targetName)
    if not targetName or targetName == "" then return end
    if IsWargameInstance() then return end -- 12.0.5: addon comms blocked in-instance
    -- Rate-limit: don't ping same target within 5 minutes
    local now = time()
    if WG._lastPingTime[targetName] and (now - WG._lastPingTime[targetName]) < 300 then
        return
    end
    WG._lastPingTime[targetName] = now
    SendV2("PING", targetName, UnitName("player"))
end

-- ---------- PUBLIC: Start ban phase ----------
function WG.StartBanPhase(opponentName, mapPool, bansPerPlayer)
    if not opponentName or opponentName == "" then return end
    if not WG.addonUsers[opponentName] or (time() - WG.addonUsers[opponentName]) > 3600 then
        print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["MSG_OPPONENT_NO_ADDON"])
        return
    end

    WG.banState = "selecting"
    WG._banData = {
        opponent = opponentName,
        mapPool = mapPool,
        maxBans = bansPerPlayer,
        myBans = {},
        theirBans = nil,
        initiator = true,
    }

    -- Send BAN_INIT: bansPerPlayer + map pool
    local parts = {tostring(bansPerPlayer)}
    for _, m in ipairs(mapPool) do
        table.insert(parts, m)
    end
    SendV2("BAN_INIT", opponentName, unpack(parts))

    -- Timeout: if no PONG within 5 seconds, cancel
    C_Timer.After(5, function()
        if WG.banState == "selecting" and WG._banData and WG._banData.initiator and not WG._banData.theirBans then
            -- Check if we got a PONG (addonUsers updated)
            local ts = WG.addonUsers[opponentName]
            if not ts or (time() - ts) > 10 then
                WG.banState = nil
                WG._banData = nil
                print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["BAN_CANCELLED"] .. " " .. L["MSG_OPPONENT_NO_ADDON"])
                if WG.mainFrame and WG.mainFrame.RefreshBanMode then
                    WG.mainFrame:RefreshBanMode()
                end
            end
        end
    end)
end

-- ---------- PUBLIC: Submit local bans ----------
function WG.SubmitBans(bans)
    if not WG._banData then return end
    WG._banData.myBans = bans

    -- Send BAN_PICK to opponent
    SendV2("BAN_PICK", WG._banData.opponent, unpack(bans))

    -- Only initiator resolves when both sides submitted
    if WG._banData.initiator and WG._banData.theirBans then
        ResolveBanResult()
    else
        WG.banState = "waiting"
        print("|cff" .. WG.GetActiveTheme().inlineAccent .. L["CHAT_PREFIX"] .. "|r " .. L["BAN_WAITING"])
        if WG.mainFrame and WG.mainFrame.RefreshBanMode then
            WG.mainFrame:RefreshBanMode()
        end
    end
end

-- ---------- PUBLIC: Cancel ban phase ----------
function WG.CancelBanPhase()
    if not WG._banData then return end
    local opponent = WG._banData.opponent
    if opponent and opponent ~= "" then
        SendV2("BAN_CANCEL", opponent, UnitName("player"))
    end
    WG.banState = nil
    WG._banData = nil
    if WG.mainFrame and WG.mainFrame.RefreshBanMode then
        WG.mainFrame:RefreshBanMode()
    end
end

-- ---------- PUBLIC: Broadcast presence to party (cross-faction addon detection) ----------
function WG.BroadcastPresence()
    if IsWargameInstance() then return end
    local ch = GetChannel()
    if not ch then return end
    SendV2Party("PING", UnitName("player"))
end

-- ---------- PUBLIC: Broadcast match result to party ----------
-- PVP_MATCH_COMPLETE fires inside the instance, where SendAddonMessage is
-- blocked in 12.0.5. We cache the winner and let the zone-out handler flush
-- it via FlushBufferedMatchResult. Safety net: drop the cache after 5 min.
function WG.BroadcastMatchResult(winner)
    WG._matchGeneration = WG._matchGeneration + 1
    local gen = WG._matchGeneration
    WG._lastMatchWinner = winner
    C_Timer.After(300, function()
        if WG._matchGeneration == gen then
            WG._lastMatchWinner = nil
        end
    end)

    -- If this ever fires outside the instance, send immediately and clear
    -- the cache so the zone-out flush doesn't re-broadcast.
    if IsWargameInstance() then return end
    local ch = GetChannel()
    if not ch then return end
    SendV2Party("MATCH_SYNC", tostring(winner))
    WG._lastMatchWinner = nil
end

-- ---------- PUBLIC: Request match sync from party ----------
function WG.RequestMatchSync()
    if IsWargameInstance() then return end
    local ch = GetChannel()
    if not ch then return end
    SendV2Party("SYNC_REQUEST", UnitName("player"))
end

-- ---------- ZONE TRANSITION HANDLING ----------
-- Flushes a buffered match result to the party on zone-out.
-- BroadcastMatchResult caches `_lastMatchWinner` because PVP_MATCH_COMPLETE
-- fires inside the instance where SendAddonMessage is blocked (12.0.5+).
-- On the first PLAYER_ENTERING_WORLD outside the wargame instance, we flush.
local function FlushBufferedMatchResult()
    if WG._lastMatchWinner == nil then return end
    local ch = GetChannel()
    if ch then
        SendV2Party("MATCH_SYNC", tostring(WG._lastMatchWinner))
        WG._lastMatchWinner = nil
    end
end

local function OnPlayerEnteringWorld(isLogin, isReload)
    if isLogin then return end

    if IsWargameInstance() then
        -- Reload landed us back inside the arena/BG. Recover local match state;
        -- cross-party result sync is unreachable from in-instance in 12.0.5.
        if isReload and WG.lastChallenge and WG.AttemptReloadRecovery then
            WG.AttemptReloadRecovery()
        end
        return
    end

    -- Zoned out of (or reloaded outside of) the wargame: flush any cached result.
    FlushBufferedMatchResult()
end

-- ---------- RECEIVER ----------
local function OnAddonMessage(prefix, msg, channel, sender)
    if prefix ~= PREFIX then return end

    -- Ignore our own broadcasts
    local selfName = Ambiguate(sender, "all")
    if selfName == UnitName("player") then return end

    -- Remember which realm we last heard this addon user from, so we can whisper
    -- them back cross-realm (addonUsers itself is keyed by short name).
    local rawBase, rawRealm = tostring(sender):match("^(.-)%-(.+)$")
    if rawBase and rawBase ~= "" and rawRealm and rawRealm ~= "" then
        WG.addonUserRealms[rawBase] = (rawRealm:gsub("[%s']", ""))
    end

    -- Reassemble multi-part payloads before anything else looks at the message.
    if msg:sub(1, 4) == "V2C:" then
        local full = ReassembleChunk(selfName, msg)
        if not full then return end
        msg = full
    end

    -- Check for V2 message format first
    local msgType, rest = ParseV2(msg)
    if msgType then
        local handler = V2_HANDLERS[msgType]
        if handler then
            handler(selfName, rest or "", channel)
        end
        return
    end

    -- Legacy V1: Don't overwrite if we already have challenge data
    if WG.lastChallenge then return end

    local challenge = Deserialize(msg)
    if not challenge then return end

    WG.lastChallenge = challenge
    WG_History.lastChallenge = challenge

    -- Relay to our own party so our teammates also get the data
    -- Only relay whispers (direct from opponent), not party messages (already relayed).
    -- Skip if inside the wargame instance — 12.0.5 blocks SendAddonMessage there.
    if channel == "WHISPER" and not IsWargameInstance() then
        local ch = GetChannel()
        if ch then
            C_ChatInfo.SendAddonMessage(PREFIX, msg, ch)
        end
    end
end

-- ---------- PUBLIC: Expose V2 senders for veto.lua / readycheck.lua ----------
WG.SendV2 = SendV2
WG.SendV2Party = SendV2Party

-- ================================================================
-- DEBUG TEST MODE for Ban Maps
-- Usage: /run WargamesPlus.BanTest()
--        /run WargamesPlus.BanTest(3)   -- 3 bans per player
-- Simulates a ban session locally. You pick your bans, submit,
-- then a simulated opponent bans random maps and the result resolves.
-- No comms are sent, no opponent is needed.
-- ================================================================
function WG.BanTest(bansPerPlayer)
    bansPerPlayer = bansPerPlayer or 2

    -- Need the UI open
    if not WG.mainFrame then
        print("|cffff6060[BanTest]|r Open the WG+ window first (/war).")
        return
    end

    -- Cancel any existing ban phase
    if WG.banState then
        WG.banState = nil
        WG._banData = nil
        if WG.mainFrame.RefreshBanMode then WG.mainFrame:RefreshBanMode() end
    end

    -- Build arena map pool (skip "Random Map")
    local mapPool = {
        "Nagrand Arena", "Blade's Edge Arena", "Ruins of Lordaeron",
        "Dalaran Arena", "Ring of Valor", "Tol'viron Arena", "Tiger's Peak",
        "Ashamane's Fall", "Black Rook Hold Arena", "Hook Point",
        "Mugambala", "Maldraxxus Coliseum", "Nokhudon Proving Grounds",
    }

    if #mapPool < 3 then
        print("|cffff6060[BanTest]|r Not enough maps.")
        return
    end

    -- Set up ban state as initiator
    WG.banState = "selecting"
    WG._banData = {
        opponent = "TestOpponent",
        mapPool = mapPool,
        maxBans = bansPerPlayer,
        myBans = {},
        theirBans = nil,
        initiator = true,
        _testMode = true,
    }

    local t = WG.GetActiveTheme()
    print("|cff" .. t.inlineAccent .. "[BanTest]|r Ban test started. Select " .. bansPerPlayer .. " maps to ban, then click Submit Bans.")
    print("|cff" .. t.inlineAccent .. "[BanTest]|r Opponent will ban " .. bansPerPlayer .. " random maps after you submit.")

    -- Trigger UI into ban mode
    if WG.mainFrame.RefreshBanMode then WG.mainFrame:RefreshBanMode() end
end

-- Hook SubmitBans to handle test mode
local OrigSubmitBans = WG.SubmitBans
WG.SubmitBans = function(bans)
    if not WG._banData or not WG._banData._testMode then
        return OrigSubmitBans(bans)
    end

    local bd = WG._banData
    bd.myBans = bans
    local t = WG.GetActiveTheme()

    print("|cff" .. t.inlineAccent .. "[BanTest]|r Your bans:")
    for _, m in ipairs(bans) do
        print("  |cff" .. t.inlineLoss .. m .. "|r")
    end

    -- Simulate opponent bans: pick random maps that weren't already banned
    local myBanSet = {}
    for _, m in ipairs(bans) do myBanSet[m] = true end

    local available = {}
    for _, m in ipairs(bd.mapPool) do
        if not myBanSet[m] then
            table.insert(available, m)
        end
    end

    local oppBans = {}
    for i = 1, bd.maxBans do
        if #available == 0 then break end
        local idx = math.random(1, #available)
        table.insert(oppBans, available[idx])
        table.remove(available, idx)
    end
    bd.theirBans = oppBans

    print("|cff" .. t.inlineAccent .. "[BanTest]|r Opponent bans:")
    for _, m in ipairs(oppBans) do
        print("  |cff" .. t.inlineLoss .. m .. "|r")
    end

    -- Resolve: combine bans, pick from remaining
    local banned = {}
    for _, m in ipairs(bd.myBans) do banned[m] = true end
    for _, m in ipairs(bd.theirBans) do banned[m] = true end

    local remaining = {}
    for _, m in ipairs(bd.mapPool) do
        if not banned[m] then
            table.insert(remaining, m)
        end
    end
    if #remaining == 0 then remaining = bd.mapPool end

    local selected = remaining[math.random(1, #remaining)]

    WG.banState = "complete"
    print("|cff" .. t.inlineAccent .. "[BanTest]|r === RESULT ===")
    print("|cff" .. t.inlineAccent .. "[BanTest]|r Map selected: |cff" .. t.inlineGreen .. selected .. "|r")
    print("|cff" .. t.inlineAccent .. "[BanTest]|r Remaining pool: " .. #remaining .. " maps")

    -- Auto-fill map selection in UI
    if WG.mainFrame and WG.mainFrame.SelectMapByName then
        WG.mainFrame:SelectMapByName(selected)
    end

    -- Clean up after short delay
    C_Timer.After(2, function()
        WG.banState = nil
        WG._banData = nil
        if WG.mainFrame and WG.mainFrame.RefreshBanMode then
            WG.mainFrame:RefreshBanMode()
        end
    end)
end

-- ---------- EVENT FRAME ----------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        OnPlayerEnteringWorld(...)
    elseif event == "CHAT_MSG_ADDON" then
        OnAddonMessage(...)
    elseif event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(1, function()
            if IsInGroup() then WG.BroadcastPresence() end
        end)
    end
end)
