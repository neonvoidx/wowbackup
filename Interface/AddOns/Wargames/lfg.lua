-- lfg.lua: WarGames+ LFG (Looking For Wargames) panel
-- Silent-joins a custom chat channel (WGPlusLFG) and the player's guild channel,
-- broadcasts wargame availability, and lists other advertisers.
-- Plain chat messages are used (not addon messages) because custom chat channels
-- survive the 12.0.5 addon-comm-in-instance restriction and reach cross-realm
-- guildmates via GUILD.

local WG = _G["WargamesPlus"]
if not WG then return end
local L = WG.L or setmetatable({}, { __index = function(_, k) return tostring(k) end })

local FONT = WG.ADDON_FONT

-- ============================================================
-- Constants
-- ============================================================
local MAGIC_PREFIX   = "[WG+LFG]"
local ADDON_PREFIX   = "WGPLFG"  -- C_ChatInfo addon-message prefix (≤16 chars)
local PROTOCOL_VER   = 1
-- "WargamesPlus" community / "lfg-traffic" stream, identified by ID rather than name: as of the
-- Midnight secret-values system, C_Club name fields are unconditionally unreadable/uncomparable by
-- addon code (indexing or comparing them throws), so matching by name is no longer possible.
local COMMUNITY_CLUB_ID = 500708981
local COMMUNITY_STREAM_ID = 2
local POST_EXPIRY    = 600   -- 10 minutes; a post is considered live this long after lastSeen
local REFRESH_PERIOD = 120   -- re-broadcast our own post every N seconds
local POST_COOLDOWN  = 60    -- minimum gap between our own outbound posts
local HISTORY_DEDUPE = 300   -- don't log same (charKey, bracket) twice within 5 minutes
local HISTORY_MAX    = 200
local FRAME_W, FRAME_H = 460, 600
local ROW_HEIGHT     = 32

local BRACKETS = { "ARENA_2V2", "ARENA_3V3", "ARENA_5V5", "SOLO_SHUFFLE", "BG", "BLITZ" }
local BRACKET_LABEL = {
    ARENA_2V2 = "2v2", ARENA_3V3 = "3v3", ARENA_5V5 = "5v5",
    SOLO_SHUFFLE = "Shuffle", BG = "BG", BLITZ = "Blitz",
}

-- ============================================================
-- State
-- ============================================================
local livePosts    = {}     -- [charKey] = { poster, realm, bracket, note, faction, lastSeen }
local myPost       = nil    -- our active post, or nil if unposted
local lastPostTime = 0
local refreshTimer = nil
local expireTimer  = nil
local lfgFrame     = nil    -- UI frame, created on first Toggle

-- Filter state (live mode)
local filterBracket = "ANY"    -- "ANY" or a BRACKET key
local filterFaction = "ALL"    -- "ALL" | "H" | "A"
local filterSearch  = ""        -- substring matched case-insensitively against note
local viewMode      = "live"   -- "live" | "history"

-- Community transport state (resolved on login if the user has joined the shared community)
local communityTarget = nil    -- { clubId = "...", streamId = "..." } or nil

-- ============================================================
-- Helpers
-- ============================================================
local function ChatPrefix()
    return "|cff" .. (WG.GetActiveTheme().inlineAccent or "00a3cc") .. L["CHAT_PREFIX"] .. "|r"
end

local function Print(msg)
    print(ChatPrefix() .. " " .. msg)
end

local function CharKey(name, realm)
    if not name or name == "" then return nil end
    realm = realm and realm ~= "" and realm or GetRealmName()
    return name .. "-" .. realm
end

-- Realm-normalized identity for the local player, used as the livePosts key
-- for our own listing so it shows up in the live list alongside everyone else's.
local function OwnRealm()
    return (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName()
end

local function OwnCharKey()
    return UnitName("player") .. "-" .. OwnRealm()
end

local function IsWargameInstance()
    if WG.IsWargameInstance then return WG.IsWargameInstance() end
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "arena" or instanceType == "pvp")
end

local function AgeString(secondsAgo)
    if secondsAgo < 60 then return L["LFG_JUST_NOW"] end
    return string.format(L["LFG_MIN_AGO"], math.floor(secondsAgo / 60))
end

local function FactionTag()
    local f = UnitFactionGroup("player")
    if f == "Horde" then return "H"
    elseif f == "Alliance" then return "A" end
    return "N"
end

-- Addon-detected badge: returns true if the poster has pinged/ponged through comm.lua
-- within the last hour. Tries full "Name-Realm" key and the bare short name.
local function HasAddonBadge(poster, realm)
    if not poster or not WG.addonUsers then return false end
    local now = time()
    local fullKey = poster .. (realm and ("-" .. realm) or "")
    local ts = WG.addonUsers[fullKey] or WG.addonUsers[poster]
    if ts and (now - ts) < 3600 then return true end
    for k, v in pairs(WG.addonUsers) do
        local short = k:match("^([^-]+)")
        if short == poster and (now - v) < 3600 then return true end
    end
    return false
end

-- Head-to-head against a poster name. Returns (wins, losses) walking WG_History.records.
local function HeadToHead(poster)
    local records = WG_History.records
    if not records or not poster then return 0, 0 end
    local w, l = 0, 0
    for i = 1, #records do
        local r = records[i]
        if r.opponent == poster then
            if r.result == "win" then w = w + 1
            elseif r.result == "loss" then l = l + 1 end
        end
    end
    return w, l
end

-- Post passes the active filter bar
local function PassesFilter(p)
    if filterBracket ~= "ANY" and p.bracket ~= filterBracket then return false end
    if filterFaction ~= "ALL" and p.faction ~= filterFaction then return false end
    if filterSearch ~= "" then
        local s = filterSearch:lower()
        if not (p.note and p.note:lower():find(s, 1, true)) then return false end
    end
    return true
end

local function CycleFaction(cur)
    if cur == "ALL" then return "H"
    elseif cur == "H" then return "A"
    else return "ALL" end
end

local function FactionFilterLabel(cur)
    if cur == "H" then return L["LFG_FACTION_HORDE"]
    elseif cur == "A" then return L["LFG_FACTION_ALLIANCE"]
    else return L["LFG_FACTION_ALL"] end
end

-- ============================================================
-- Serialization
-- ============================================================
-- Format: [WG+LFG];v=1;b=ARENA_3V3;f=H;n=chill practice;exp=1713562800
-- Semicolon-separated key=value pairs. WoW's chat parser treats `|` as an
-- escape prefix, so notes are sanitized to strip both `|` and `;`.
local function Serialize(post)
    local note = (post.note or ""):gsub("|", "/"):gsub(";", ","):gsub("\t", " ")
    if #note > 80 then note = note:sub(1, 80) end
    return table.concat({
        MAGIC_PREFIX,
        "v=" .. PROTOCOL_VER,
        "b=" .. post.bracket,
        "f=" .. (post.faction or FactionTag()),
        "n=" .. note,
        "exp=" .. (post.expiresAt or (time() + POST_EXPIRY)),
    }, ";")
end

local function Deserialize(msg)
    if not msg or not msg:find(MAGIC_PREFIX, 1, true) then return nil end
    local body = msg:match("^%[WG%+LFG%];(.+)$")
    if not body then return nil end
    local parsed = {}
    for part in body:gmatch("[^;]+") do
        local k, v = part:match("^(%w+)=(.*)$")
        if k then parsed[k] = v end
    end
    if tonumber(parsed.v) ~= PROTOCOL_VER then return nil end
    if not parsed.b or not BRACKET_LABEL[parsed.b] then return nil end
    return {
        bracket   = parsed.b,
        faction   = parsed.f or "N",
        note      = parsed.n or "",
        expiresAt = tonumber(parsed.exp) or (time() + POST_EXPIRY),
    }
end

-- ============================================================
-- Custom popup: selectable invite link for the WargamesPlus community
-- (built manually instead of via StaticPopupDialogs' hasEditBox, which
-- was unreliable at rendering the edit box's text on current clients)
-- ============================================================
local inviteBox
local function ShowCommunityInviteBox()
    if not inviteBox then
        local f = CreateFrame("Frame", "WG_LFGInviteBox", UIParent, "BackdropTemplate")
        f:SetSize(380, 110)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        WG.ApplyModernStyle(f)
        if WG.ApplyUIScale then WG.ApplyUIScale(f) end

        local prompt = f:CreateFontString(nil, "OVERLAY")
        prompt:SetFont(FONT, 11)
        prompt:SetPoint("TOPLEFT", 14, -14)
        prompt:SetPoint("TOPRIGHT", -14, -14)
        prompt:SetJustifyH("LEFT")
        prompt:SetText(L["LFG_COMMUNITY_COPY_PROMPT"])

        local editBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        editBox:SetSize(350, 24)
        editBox:SetPoint("TOP", prompt, "BOTTOM", 0, -16)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function() f:Hide() end)
        editBox:SetScript("OnEnterPressed", function() f:Hide() end)
        if WG.StyleInput then WG.StyleInput(editBox) end
        f.editBox = editBox

        local openPanelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        openPanelBtn:SetSize(160, 22)
        openPanelBtn:SetPoint("BOTTOM", -44, 14)
        openPanelBtn:SetText(L["LFG_COMMUNITY_OPEN_PANEL"])
        if WG.StyleButton then WG.StyleButton(openPanelBtn) end
        openPanelBtn:SetScript("OnClick", function()
            if ToggleGuildFrame then ToggleGuildFrame() end
        end)

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        closeBtn:SetSize(80, 22)
        closeBtn:SetPoint("LEFT", openPanelBtn, "RIGHT", 8, 0)
        closeBtn:SetText(CLOSE or "Close")
        if WG.StyleButton then WG.StyleButton(closeBtn) end
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        f:Hide()
        inviteBox = f
    end

    inviteBox.editBox:SetText(L["LFG_COMMUNITY_INVITE_URL"])
    inviteBox:Show()
    inviteBox.editBox:SetFocus()
    inviteBox.editBox:HighlightText()
end

-- ============================================================
-- Addon-message prefix registration
-- ============================================================
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

-- ============================================================
-- History logging
-- ============================================================
local function LogHistory(charKey, post)
    local hist = WG_History.lfgHistory
    if not hist then return end
    local now = time()
    -- Dedupe: skip if same (charKey, bracket) logged within HISTORY_DEDUPE
    for i = #hist, math.max(1, #hist - 10), -1 do
        local e = hist[i]
        if e and e.charKey == charKey and e.bracket == post.bracket
                and (now - (e.seenAt or 0)) < HISTORY_DEDUPE then
            return
        end
    end
    table.insert(hist, {
        charKey = charKey,
        bracket = post.bracket,
        faction = post.faction,
        note    = post.note,
        seenAt  = now,
    })
    while #hist > HISTORY_MAX do
        table.remove(hist, 1)
    end
end

-- ============================================================
-- Inbound message handling
-- ============================================================
local function HandleIncoming(msg, senderFull)
    if not senderFull or senderFull == "" then return end
    -- Strip our own posts.
    -- Community/guild events deliver server-normalized realm names (spaces stripped),
    -- so compare with GetNormalizedRealmName() to match on multi-word realms.
    local normRealm = (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName()
    local playerKey = UnitName("player") .. "-" .. normRealm
    local senderKey = senderFull
    if not senderFull:find("-", 1, true) then
        senderKey = senderFull .. "-" .. normRealm
    end
    if senderKey == playerKey then return end

    local post = Deserialize(msg)
    if not post then return end

    local name, realm = senderFull:match("^([^-]+)-?(.*)$")
    realm = (realm and realm ~= "") and realm or GetRealmName()

    -- Ignored posters are silently dropped
    if WG_History.lfgIgnore and WG_History.lfgIgnore[senderKey] then return end

    -- Merge into live cache (either transport may arrive first)
    livePosts[senderKey] = {
        poster    = name,
        realm     = realm,
        bracket   = post.bracket,
        faction   = post.faction,
        note      = post.note,
        lastSeen  = time(),
        expiresAt = post.expiresAt,
    }

    LogHistory(senderKey, post)

    if lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
        lfgFrame:Refresh()
    end
end

-- ============================================================
-- Expire sweep
-- ============================================================
local function SweepExpired()
    local now = time()
    local changed = false
    for k, p in pairs(livePosts) do
        if (p.expiresAt and now > p.expiresAt) or (now - (p.lastSeen or 0)) > POST_EXPIRY then
            livePosts[k] = nil
            changed = true
        end
    end
    if changed and lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
        lfgFrame:Refresh()
    end
end

-- ============================================================
-- Outbound broadcast
-- ============================================================
local function SendToGuild(msg)
    if not IsInGuild() then return false end
    -- Addon message, NOT SendChatMessage — guildmates must not see the raw payload.
    -- LFG posting is already blocked inside instances (12.0.5 restriction), so
    -- this only ever runs from the open world where addon comms work fine.
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, msg, "GUILD")
    return true
end

local function SendToCommunity(msg)
    if not communityTarget or not C_Club then return false end
    C_Club.SendMessage(communityTarget.clubId, communityTarget.streamId, msg)
    return true
end

local function Broadcast(isInitial)
    if not myPost then return end
    if IsWargameInstance() then return end  -- addon comms blocked in-instance (12.0.5)
    local now = time()
    if (now - lastPostTime) < POST_COOLDOWN then return end
    myPost.expiresAt = now + POST_EXPIRY
    -- Keep the one-shot unpost timer in sync with the advancing expiresAt
    if expireTimer then expireTimer:Cancel() end
    expireTimer = C_Timer.NewTimer(POST_EXPIRY, function()
        if myPost then WG.LFG_Unpost() end
    end)
    local payload = Serialize(myPost)
    local any = false
    if SendToGuild(payload) then any = true end
    -- C_Club.SendMessage is a protected call — Blizzard only allows it in direct
    -- response to a hardware event (the post button click), not from the
    -- refresh ticker. Only hit the community stream on the initial post.
    if isInitial and SendToCommunity(payload) then any = true end
    if any then lastPostTime = now end

    -- Keep our own entry in livePosts fresh so it stays visible (and doesn't expire) locally
    local ownEntry = livePosts[OwnCharKey()]
    if ownEntry then
        ownEntry.lastSeen = now
        ownEntry.expiresAt = myPost.expiresAt
    end
end

-- ============================================================
-- Community detection (C_Club)
-- ============================================================
-- Walks the subscribed clubs looking for the known WargamesPlus community by clubId
-- (clubId/streamId stay readable under secret-values; name does not — see above).
-- If found, picks the dedicated stream within it. Results are cached in
-- `communityTarget`; prints a one-time hint if the community is joined but the
-- stream is absent (so the user knows to update the invite).
local function DetectCommunity()
    if not C_Club or not C_Club.GetSubscribedClubs then
        communityTarget = nil
        return
    end
    local clubs = C_Club.GetSubscribedClubs() or {}
    local matchedClub
    for _, club in ipairs(clubs) do
        if club.clubId == COMMUNITY_CLUB_ID then
            matchedClub = club
            break
        end
    end
    if not matchedClub then
        communityTarget = nil
        return
    end

    local streams = C_Club.GetStreams(matchedClub.clubId) or {}
    for idx, stream in ipairs(streams) do
        -- streamId can be a secret value under 12.0's taint rules; comparing it
        -- may throw, so fall back to matching by position when that happens.
        local ok, isMatch = pcall(function() return stream.streamId == COMMUNITY_STREAM_ID end)
        if (ok and isMatch) or (not ok and idx == COMMUNITY_STREAM_ID) then
            communityTarget = { clubId = matchedClub.clubId, streamId = COMMUNITY_STREAM_ID }
            return
        end
    end

    -- Community present but dedicated stream missing — warn once
    communityTarget = nil
    if not WG_History.lfgCommunityHintShown then
        WG_History.lfgCommunityHintShown = true
        Print(L["LFG_COMMUNITY_STREAM_MISSING"])
    end
end

-- ============================================================
-- Public API
-- ============================================================
function WG.LFG_Post(bracket, note)
    if not WG_History.lfgEnabled then
        Print(L["LFG_DISABLED"])
        return
    end
    if not BRACKET_LABEL[bracket] then return end
    if IsWargameInstance() then
        Print(L["LFG_IN_INSTANCE"])
        return
    end
    local now = time()
    if (now - lastPostTime) < POST_COOLDOWN and myPost then
        Print(L["LFG_RATE_LIMITED"])
        return
    end
    myPost = {
        bracket   = bracket,
        note      = note or "",
        faction   = FactionTag(),
        expiresAt = now + POST_EXPIRY,
    }

    -- Add/refresh our own entry so the post shows up in the live list immediately
    livePosts[OwnCharKey()] = {
        poster    = UnitName("player"),
        realm     = OwnRealm(),
        bracket   = myPost.bracket,
        faction   = myPost.faction,
        note      = myPost.note,
        lastSeen  = now,
        expiresAt = myPost.expiresAt,
        isSelf    = true,
    }

    Broadcast(true)
    Print(string.format(L["LFG_POSTED"], BRACKET_LABEL[bracket]))

    -- Schedule refresh broadcasts
    if refreshTimer then refreshTimer:Cancel() end
    refreshTimer = C_Timer.NewTicker(REFRESH_PERIOD, function()
        if myPost then Broadcast() else
            if refreshTimer then refreshTimer:Cancel(); refreshTimer = nil end
        end
    end)
    -- Auto-unpost at expiry
    if expireTimer then expireTimer:Cancel() end
    expireTimer = C_Timer.NewTimer(POST_EXPIRY, function()
        if myPost then WG.LFG_Unpost() end
    end)

    if lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
        lfgFrame:Refresh()
    end
end

function WG.LFG_Unpost()
    myPost = nil
    livePosts[OwnCharKey()] = nil
    if refreshTimer then refreshTimer:Cancel(); refreshTimer = nil end
    if expireTimer then expireTimer:Cancel(); expireTimer = nil end
    Print(L["LFG_UNPOSTED"])
    if lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
        lfgFrame:Refresh()
    end
end

function WG.LFG_GetPosts()
    SweepExpired()
    local list = {}
    for k, p in pairs(livePosts) do
        table.insert(list, {
            charKey  = k,
            poster   = p.poster,
            realm    = p.realm,
            bracket  = p.bracket,
            note     = p.note,
            faction  = p.faction,
            lastSeen = p.lastSeen,
            isSelf   = p.isSelf,
        })
    end
    table.sort(list, function(a, b) return a.lastSeen > b.lastSeen end)
    return list
end

function WG.LFG_HidePoster(charKey)
    if not charKey then return end
    if not WG_History.lfgIgnore then WG_History.lfgIgnore = {} end
    WG_History.lfgIgnore[charKey] = true
    livePosts[charKey] = nil
    if lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
        lfgFrame:Refresh()
    end
end

function WG.LFG_UnignorePoster(charKey)
    if not charKey then return end
    WG_History.lfgIgnore[charKey] = nil
    if lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
        lfgFrame:Refresh()
    end
end

function WG.LFG_GetIgnoreList()
    local list = {}
    for k in pairs(WG_History.lfgIgnore or {}) do
        table.insert(list, k)
    end
    table.sort(list)
    return list
end

-- ============================================================
-- Test helpers (invoked via /war lfgfake N and /war lfgclear)
-- ============================================================
local FAKE_NAMES = {
    "Zugzug", "Furiosa", "Blademonk", "Icewind", "Shatterstep", "Hexina",
    "Vengar", "Mournblade", "Skullrend", "Kaelith", "Pyrowrath", "Shadovar",
    "Brineheart", "Thornwake", "Glimmerhoof", "Ravnor",
}
local FAKE_REALMS = { "Illidan", "Tichondrius", "Area52", "Stormrage", "Mal'Ganis" }
local FAKE_NOTES = {
    "chill practice", "need rating points", "bored", "tourney prep", "new comp",
    "quick games", "", "", "learning this matchup", "LFM arenas",
}

function WG.LFG_InjectFake(n)
    n = tonumber(n) or 5
    local now = time()
    local used = {}
    for i = 1, n do
        local name
        for _ = 1, 10 do
            name = FAKE_NAMES[math.random(#FAKE_NAMES)]
            if not used[name] then used[name] = true; break end
        end
        local realm = FAKE_REALMS[math.random(#FAKE_REALMS)]
        local bracket = BRACKETS[math.random(#BRACKETS)]
        local faction = ({"H", "A"})[math.random(2)]
        local note = FAKE_NOTES[math.random(#FAKE_NOTES)]
        local ageSec = math.random(0, 9 * 60)
        local key = name .. "-" .. realm
        livePosts[key] = {
            poster    = name,
            realm     = realm,
            bracket   = bracket,
            faction   = faction,
            note      = note,
            lastSeen  = now - ageSec,
            expiresAt = now + POST_EXPIRY - ageSec,
        }
    end
    Print(string.format("Injected %d fake LFG posts.", n))
    if lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
        lfgFrame:Refresh()
    end
end

function WG.LFG_ClearLive()
    local count = 0
    for _ in pairs(livePosts) do count = count + 1 end
    wipe(livePosts)
    Print(string.format("Cleared %d live LFG posts.", count))
    if lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
        lfgFrame:Refresh()
    end
end

-- Rows for the history log mode (reads WG_History.lfgHistory)
local function GetHistoryRows()
    local rows = {}
    local hist = WG_History.lfgHistory or {}
    for i = #hist, 1, -1 do
        local e = hist[i]
        local name, realm = (e.charKey or ""):match("^([^-]+)-?(.*)$")
        table.insert(rows, {
            charKey  = e.charKey,
            poster   = name or e.charKey,
            realm    = realm,
            bracket  = e.bracket,
            note     = e.note,
            faction  = e.faction,
            lastSeen = e.seenAt,
        })
    end
    return rows
end

-- Build map pool for a given bracket key (used by veto integration)
local function MapPoolForBracket(bracket)
    if not WG.GetSortedMapList then return {} end
    local modeKey
    if bracket == "BG" then modeKey = "BG"
    elseif bracket == "BLITZ" then modeKey = "BLITZ"
    else modeKey = "ARENA" end
    local full = WG.GetSortedMapList(modeKey) or {}
    local pool = {}
    for i = 1, #full do
        if full[i] ~= "Random Map" then
            table.insert(pool, full[i])
        end
    end
    return pool
end

-- ============================================================
-- UI
-- ============================================================
-- Promoted to uikit.lua (was local to this file only); aliased so every existing
-- call-site below keeps working unchanged.
local CreateChip = WG.CreateChip
local StyleCard = WG.StyleCard
local AddPlaceholder = WG.AddPlaceholder

local function BuildFrame()
    if lfgFrame then return lfgFrame end
    local mainFrame = WG.mainFrame
    if not mainFrame then return nil end

    local f = CreateFrame("Frame", "WG_LFGFrame", mainFrame, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 5, 0)
    f:SetFrameStrata("HIGH")
    if WG.ApplyModernStyle then WG.ApplyModernStyle(f) end

    -- Shared chrome (accent stripe + title + close) — this panel already got titleColor
    -- right (the only one that did), so this mainly standardizes the close glyph
    -- (was lowercase "x") and exact stripe/title metrics with every other window.
    local chrome = WG.CreateWindowChrome(f, { title = L["LFG_TITLE"], titleSize = 13 })
    f.title = chrome.title

    -- Segmented Live/History control, sitting just left of the close button
    local historyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    historyBtn:SetSize(50, 20)
    historyBtn:SetPoint("TOPRIGHT", -34, -10)
    historyBtn:SetText(L["LFG_MODE_HISTORY"])
    if WG.StyleButton then WG.StyleButton(historyBtn) end
    historyBtn.bar = historyBtn:CreateTexture(nil, "OVERLAY")
    historyBtn.bar:SetHeight(2)
    historyBtn.bar:SetPoint("BOTTOMLEFT", 2, 1)
    historyBtn.bar:SetPoint("BOTTOMRIGHT", -2, 1)

    local liveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    liveBtn:SetSize(42, 20)
    liveBtn:SetPoint("RIGHT", historyBtn, "LEFT", -2, 0)
    liveBtn:SetText(L["LFG_MODE_LIVE"])
    if WG.StyleButton then WG.StyleButton(liveBtn) end
    liveBtn.bar = liveBtn:CreateTexture(nil, "OVERLAY")
    liveBtn.bar:SetHeight(2)
    liveBtn.bar:SetPoint("BOTTOMLEFT", 2, 1)
    liveBtn.bar:SetPoint("BOTTOMRIGHT", -2, 1)

    local function UpdateModeButtons()
        local ac = WG.GetActiveTheme().accent
        liveBtn.bar:SetColorTexture(ac[1], ac[2], ac[3], viewMode == "live" and 1 or 0)
        historyBtn.bar:SetColorTexture(ac[1], ac[2], ac[3], viewMode == "history" and 1 or 0)
    end
    liveBtn:SetScript("OnClick", function()
        viewMode = "live"
        UpdateModeButtons()
        f:Refresh()
    end)
    historyBtn:SetScript("OnClick", function()
        viewMode = "history"
        UpdateModeButtons()
        f:Refresh()
    end)
    f.UpdateModeButtons = UpdateModeButtons
    UpdateModeButtons()

    -- ===== "Post a Listing" section =====
    local postLabel = f:CreateFontString(nil, "OVERLAY")
    postLabel:SetFont(FONT, 10, "OUTLINE")
    postLabel:SetPoint("TOPLEFT", 15, -40)
    postLabel:SetText(L["LFG_SECTION_POST"])
    local hc1 = WG.GetActiveTheme().headerColor
    postLabel:SetTextColor(hc1[1], hc1[2], hc1[3], 1)
    if WG.RegisterThemedElement then
        WG.RegisterThemedElement(postLabel, function(fs)
            local h2 = WG.GetActiveTheme().headerColor
            fs:SetTextColor(h2[1], h2[2], h2[3], 1)
        end)
    end

    local composeCard = CreateFrame("Frame", nil, f, "BackdropTemplate")
    composeCard:SetPoint("TOPLEFT", 10, -52)
    composeCard:SetPoint("TOPRIGHT", -10, -52)
    composeCard:SetHeight(100)
    StyleCard(composeCard)

    f.bracketLabel = f:CreateFontString(nil, "OVERLAY")
    f.bracketLabel:SetFont(FONT, 11)
    f.bracketLabel:SetPoint("TOPLEFT", 20, -66)
    f.bracketLabel:SetText(L["LFG_BRACKET"])

    local dropdown = CreateFrame("Frame", "WG_LFGBracketDropdown", f, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 60, -60)
    UIDropDownMenu_SetWidth(dropdown, 100)
    WG.StyleDropdown(dropdown)
    f.bracketDropdown = dropdown
    f.selectedBracket = "ARENA_3V3"
    UIDropDownMenu_Initialize(dropdown, function()
        for _, b in ipairs(BRACKETS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = BRACKET_LABEL[b]
            info.value = b
            info.func = function(self)
                f.selectedBracket = self.value
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, BRACKET_LABEL[self.value])
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropdown, f.selectedBracket)
    UIDropDownMenu_SetText(dropdown, BRACKET_LABEL[f.selectedBracket])

    f.noteLabel = f:CreateFontString(nil, "OVERLAY")
    f.noteLabel:SetFont(FONT, 11)
    f.noteLabel:SetPoint("TOPLEFT", 20, -96)
    f.noteLabel:SetText(L["LFG_NOTE"])

    local noteBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    noteBox:SetSize(300, 24)
    noteBox:SetPoint("TOPLEFT", 60, -92)
    noteBox:SetAutoFocus(false)
    noteBox:SetMaxLetters(80)
    if WG.StyleInput then WG.StyleInput(noteBox) end
    AddPlaceholder(noteBox, L["LFG_NOTE_PLACEHOLDER"])
    f.noteBox = noteBox

    local postBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    postBtn:SetSize(90, 24)
    postBtn:SetPoint("TOPLEFT", 20, -124)
    postBtn:SetText(L["LFG_POST"])
    if WG.StyleButton then WG.StyleButton(postBtn) end
    postBtn:SetScript("OnClick", function()
        if myPost then
            WG.LFG_Unpost()
        else
            WG.LFG_Post(f.selectedBracket, noteBox:GetText())
        end
        f:Refresh()
    end)
    f.postBtn = postBtn

    f.statusText = f:CreateFontString(nil, "OVERLAY")
    f.statusText:SetFont(FONT, 10)
    f.statusText:SetPoint("LEFT", postBtn, "RIGHT", 10, 0)
    f.statusText:SetTextColor(0.85, 0.85, 0.85, 1)

    -- Separator 1 (below post card)
    local sep1 = f:CreateTexture(nil, "ARTWORK")
    sep1:SetPoint("TOPLEFT", 10, -160)
    sep1:SetPoint("TOPRIGHT", -10, -160)
    sep1:SetHeight(1)
    local acSep1 = WG.GetActiveTheme().accent
    sep1:SetColorTexture(acSep1[1], acSep1[2], acSep1[3], 0.25)
    if WG.RegisterThemedElement then
        WG.RegisterThemedElement(sep1, function(t)
            local a2 = WG.GetActiveTheme().accent
            t:SetColorTexture(a2[1], a2[2], a2[3], 0.25)
        end)
    end

    -- ===== "Filters" section =====
    local filterLabel2 = f:CreateFontString(nil, "OVERLAY")
    filterLabel2:SetFont(FONT, 10, "OUTLINE")
    filterLabel2:SetPoint("TOPLEFT", 15, -172)
    filterLabel2:SetText(L["LFG_SECTION_FILTERS"])
    local hc2 = WG.GetActiveTheme().headerColor
    filterLabel2:SetTextColor(hc2[1], hc2[2], hc2[3], 1)
    if WG.RegisterThemedElement then
        WG.RegisterThemedElement(filterLabel2, function(fs)
            local h2 = WG.GetActiveTheme().headerColor
            fs:SetTextColor(h2[1], h2[2], h2[3], 1)
        end)
    end

    local filterCard = CreateFrame("Frame", nil, f, "BackdropTemplate")
    filterCard:SetPoint("TOPLEFT", 10, -184)
    filterCard:SetPoint("TOPRIGHT", -10, -184)
    filterCard:SetHeight(44)
    StyleCard(filterCard)

    local filterBracketDD = CreateFrame("Frame", "WG_LFGFilterBracketDD", f, "UIDropDownMenuTemplate")
    filterBracketDD:SetPoint("TOPLEFT", 20, -188)
    UIDropDownMenu_SetWidth(filterBracketDD, 80)
    WG.StyleDropdown(filterBracketDD)
    f.filterBracketDD = filterBracketDD
    UIDropDownMenu_Initialize(filterBracketDD, function()
        local function addItem(value, text)
            local info = UIDropDownMenu_CreateInfo()
            info.text = text
            info.value = value
            info.func = function(self)
                filterBracket = self.value
                UIDropDownMenu_SetSelectedValue(filterBracketDD, self.value)
                UIDropDownMenu_SetText(filterBracketDD, text)
                f:Refresh()
            end
            UIDropDownMenu_AddButton(info)
        end
        addItem("ANY", L["LFG_BRACKET_ANY"])
        for _, b in ipairs(BRACKETS) do addItem(b, BRACKET_LABEL[b]) end
    end)
    UIDropDownMenu_SetSelectedValue(filterBracketDD, filterBracket)
    UIDropDownMenu_SetText(filterBracketDD, filterBracket == "ANY" and L["LFG_BRACKET_ANY"] or BRACKET_LABEL[filterBracket])

    local factionBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    factionBtn:SetSize(40, 22)
    factionBtn:SetPoint("TOPLEFT", 165, -190)
    factionBtn:SetText(FactionFilterLabel(filterFaction))
    if WG.StyleButton then WG.StyleButton(factionBtn) end
    factionBtn:SetScript("OnClick", function()
        filterFaction = CycleFaction(filterFaction)
        factionBtn:SetText(FactionFilterLabel(filterFaction))
        f:Refresh()
    end)
    f.factionBtn = factionBtn

    local searchBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    searchBox:SetSize(220, 22)
    searchBox:SetPoint("TOPLEFT", 215, -190)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(40)
    if WG.StyleInput then WG.StyleInput(searchBox) end
    AddPlaceholder(searchBox, L["LFG_SEARCH"])
    searchBox:SetScript("OnTextChanged", function(self)
        filterSearch = self:GetText() or ""
        f:Refresh()
    end)
    f.searchBox = searchBox

    -- Separator 2 (below filter card)
    local sep2 = f:CreateTexture(nil, "ARTWORK")
    sep2:SetPoint("TOPLEFT", 10, -236)
    sep2:SetPoint("TOPRIGHT", -10, -236)
    sep2:SetHeight(1)
    local acSep2 = WG.GetActiveTheme().accent
    sep2:SetColorTexture(acSep2[1], acSep2[2], acSep2[3], 0.25)
    if WG.RegisterThemedElement then
        WG.RegisterThemedElement(sep2, function(t)
            local a2 = WG.GetActiveTheme().accent
            t:SetColorTexture(a2[1], a2[2], a2[3], 0.25)
        end)
    end

    -- Community hint banner (only shown when community is not detected + not dismissed).
    -- Fixed anchor; PositionScroll shifts the header row/scroll below it when visible.
    local hintBanner = CreateFrame("Frame", nil, f, "BackdropTemplate")
    hintBanner:SetPoint("TOPLEFT", 10, -242)
    hintBanner:SetPoint("TOPRIGHT", -10, -242)
    hintBanner:SetHeight(26)
    hintBanner:SetBackdrop(WG.FLAT_BACKDROP)
    hintBanner:SetBackdropColor(0.15, 0.15, 0.2, 0.6)
    hintBanner:SetBackdropBorderColor(unpack(WG.GetActiveTheme().backdropBorder))
    hintBanner:Hide()
    f.hintBanner = hintBanner
    if WG.RegisterThemedElement then
        WG.RegisterThemedElement(hintBanner, function()
            hintBanner:SetBackdropBorderColor(unpack(WG.GetActiveTheme().backdropBorder))
        end)
    end

    -- warningColor (was a hardcoded gold literal, so it never shifted with the active
    -- theme like everything else in this panel does)
    local hintBar = hintBanner:CreateTexture(nil, "ARTWORK")
    hintBar:SetWidth(3)
    hintBar:SetPoint("TOPLEFT", 0, 0)
    hintBar:SetPoint("BOTTOMLEFT", 0, 0)
    hintBar:SetColorTexture(unpack(WG.GetActiveTheme().warningColor))
    if WG.RegisterThemedElement then
        WG.RegisterThemedElement(hintBar, function(tex) tex:SetColorTexture(unpack(WG.GetActiveTheme().warningColor)) end)
    end

    local hintText = hintBanner:CreateFontString(nil, "OVERLAY")
    hintText:SetFont(FONT, 10)
    hintText:SetPoint("LEFT", 10, 0)
    hintText:SetPoint("RIGHT", hintBanner, "RIGHT", -100, 0)
    hintText:SetJustifyH("LEFT")
    hintText:SetText(L["LFG_COMMUNITY_HINT"])
    hintText:SetTextColor(unpack(WG.GetActiveTheme().warningColor))
    if WG.RegisterThemedElement then
        WG.RegisterThemedElement(hintText, function(fs) fs:SetTextColor(unpack(WG.GetActiveTheme().warningColor)) end)
    end

    local copyBtn = CreateFrame("Button", nil, hintBanner, "UIPanelButtonTemplate")
    copyBtn:SetSize(70, 18)
    copyBtn:SetPoint("RIGHT", -24, 0)
    copyBtn:SetText(L["LFG_COMMUNITY_COPY"])
    if WG.StyleButton then WG.StyleButton(copyBtn) end
    copyBtn:SetScript("OnClick", ShowCommunityInviteBox)

    local hintClose = CreateFrame("Button", nil, hintBanner)
    hintClose:SetSize(16, 16)
    hintClose:SetPoint("RIGHT", -4, 0)
    local hintCloseLabel = hintClose:CreateFontString(nil, "OVERLAY")
    hintCloseLabel:SetFont(FONT, 11, "OUTLINE")
    hintCloseLabel:SetPoint("CENTER")
    hintCloseLabel:SetText("x")
    hintCloseLabel:SetTextColor(unpack(WG.GetActiveTheme().closeNormal))
    if WG.RegisterThemedElement then
        WG.RegisterThemedElement(hintCloseLabel, function()
            hintCloseLabel:SetTextColor(unpack(WG.GetActiveTheme().closeNormal))
        end)
    end
    hintClose:SetScript("OnClick", function()
        WG_History.lfgCommunityHintDismissed = true
        hintBanner:Hide()
        f:Refresh() -- re-anchor scroll
    end)

    -- Column header row (Name / Bracket / Note / H2H / Age), sits just above the list
    local headerRow = CreateFrame("Frame", nil, f)
    headerRow:SetHeight(14)
    local headerLine = headerRow:CreateTexture(nil, "ARTWORK")
    headerLine:SetHeight(1)
    headerLine:SetPoint("BOTTOMLEFT", 4, -2)
    headerLine:SetPoint("BOTTOMRIGHT", -4, -2)
    headerLine:SetColorTexture(1, 1, 1, 0.08)
    f.headerRow = headerRow

    local function AddHeaderLabel(anchor, x, w, text, justify)
        local fs = headerRow:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT, 9, "OUTLINE")
        fs:SetPoint(anchor, x, 0)
        fs:SetWidth(w)
        fs:SetJustifyH(justify or "LEFT")
        fs:SetText(text)
        local hcx = WG.GetActiveTheme().headerColor
        fs:SetTextColor(hcx[1], hcx[2], hcx[3], 0.85)
        if WG.RegisterThemedElement then
            WG.RegisterThemedElement(fs, function(f2)
                local h2 = WG.GetActiveTheme().headerColor
                f2:SetTextColor(h2[1], h2[2], h2[3], 0.85)
            end)
        end
        return fs
    end
    AddHeaderLabel("LEFT", 26, 100, L["LFG_COL_NAME"])
    AddHeaderLabel("LEFT", 130, 50, L["LFG_COL_BRACKET"])
    AddHeaderLabel("LEFT", 220, 100, L["LFG_COL_NOTE"])
    AddHeaderLabel("RIGHT", -56, 40, L["LFG_COL_H2H"], "RIGHT")
    AddHeaderLabel("RIGHT", -6, 48, L["LFG_COL_AGE"], "RIGHT")

    -- Scroll container (anchor adjusts based on hint visibility)
    -- Named (StyleScrollBar looks up "<name>ScrollBar" via _G, so an anonymous
    -- frame can't be reskinned) matching the WG_StatsScroll/WG_MapScroll convention.
    local scroll = CreateFrame("ScrollFrame", "WG_LFGScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("BOTTOMRIGHT", -30, 36)
    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(FRAME_W - 40, 10)
    scroll:SetScrollChild(scrollChild)
    WG.StyleScrollBar(scroll)
    f.scroll = scroll
    f.scrollChild = scrollChild
    f.rows = {}

    local function PositionScroll()
        local baseY = -244
        if hintBanner:IsShown() then
            baseY = baseY - 30
        end
        headerRow:ClearAllPoints()
        headerRow:SetPoint("TOPLEFT", 10, baseY)
        headerRow:SetPoint("TOPRIGHT", -10, baseY)
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", 10, baseY - 20)
        scroll:SetPoint("BOTTOMRIGHT", -30, 36)
    end
    f.PositionScroll = PositionScroll
    PositionScroll()

    -- Footer: reach text + post count + refresh button
    f.reachText = f:CreateFontString(nil, "OVERLAY")
    f.reachText:SetFont(FONT, 9)
    f.reachText:SetPoint("BOTTOMLEFT", 15, 28)
    f.reachText:SetTextColor(0.6, 0.6, 0.7, 1)

    -- Reach tooltip hover zone (sized to reachText after text is set in Refresh)
    local reachHover = CreateFrame("Frame", nil, f)
    reachHover:SetPoint("BOTTOMLEFT", 10, 24)
    reachHover:SetSize(260, 16)
    reachHover:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["LFG_REACH_LABEL"])
        if IsInGuild() then
            GameTooltip:AddLine("|cffffffff" .. L["LFG_REACH_GUILD"] .. "|r: " .. L["LFG_REACH_TOOLTIP_GUILD"], 1, 1, 1, true)
        end
        if communityTarget then
            GameTooltip:AddLine("|cffffffff" .. L["LFG_REACH_COMMUNITY"] .. "|r: " .. L["LFG_REACH_TOOLTIP_COMMUNITY"], 1, 1, 1, true)
        end
        if not IsInGuild() and not communityTarget then
            GameTooltip:AddLine("|cffffaaaaNo reach configured — join a guild or the WargamesPlus community.|r", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    reachHover:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f.footerText = f:CreateFontString(nil, "OVERLAY")
    f.footerText:SetFont(FONT, 10)
    f.footerText:SetPoint("BOTTOMLEFT", 15, 14)
    f.footerText:SetTextColor(0.75, 0.75, 0.75, 1)

    local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refreshBtn:SetSize(80, 22)
    refreshBtn:SetPoint("BOTTOMRIGHT", -15, 10)
    refreshBtn:SetText(L["LFG_REFRESH"])
    if WG.StyleButton then WG.StyleButton(refreshBtn) end
    refreshBtn:SetScript("OnClick", function()
        DetectCommunity()
        f:Refresh()
    end)

    -- Right-click context menu (shared single dropdown)
    local contextMenu = CreateFrame("Frame", "WG_LFGContextMenu", UIParent, "UIDropDownMenuTemplate")
    f.contextMenu = contextMenu

    local function RowClicked(row, button)
        local p = row.postData
        if not p then return end
        if p.isSelf then
            -- Your own listing: no self-challenge/whisper, just the option to pull it down
            if button == "RightButton" then
                UIDropDownMenu_Initialize(contextMenu, function()
                    local info = UIDropDownMenu_CreateInfo()
                    info.text, info.notCheckable, info.func = L["LFG_UNPOST"], true, function()
                        WG.LFG_Unpost()
                    end
                    UIDropDownMenu_AddButton(info)
                end, "MENU")
                ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 0)
            end
            return
        end
        if button == "RightButton" then
            UIDropDownMenu_Initialize(contextMenu, function()
                local function add(text, fn)
                    local info = UIDropDownMenu_CreateInfo()
                    info.text, info.notCheckable, info.func = text, true, fn
                    UIDropDownMenu_AddButton(info)
                end
                add(L["LFG_RIGHT_CLICK_CHALLENGE"], function()
                    if WG.SendChallengeByParams then
                        WG.SendChallengeByParams({
                            target   = p.poster,
                            gameMode = p.bracket,
                            mapName  = "Random Map",
                        })
                    end
                end)
                add(L["LFG_RIGHT_CLICK_VETO"], function()
                    if WG.StartVeto then
                        WG.StartVeto(p.poster, WG_History.vetoFormat or "Bo1", MapPoolForBracket(p.bracket))
                    end
                end)
                add(L["LFG_RIGHT_CLICK_WHISPER"], function()
                    ChatFrame_SendTell(p.poster)
                end)
                add(L["LFG_RIGHT_CLICK_ADD_FRIEND"], function()
                    C_FriendList.AddFriend(p.poster)
                end)
                add(L["LFG_RIGHT_CLICK_HIDE"], function()
                    WG.LFG_HidePoster(p.charKey)
                end)
            end, "MENU")
            ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 0)
        elseif button == "LeftButton" and viewMode == "live" then
            -- Quick-challenge on left-click; disabled in history mode
            if WG.SendChallengeByParams then
                WG.SendChallengeByParams({
                    target   = p.poster,
                    gameMode = p.bracket,
                    mapName  = "Random Map",
                })
            end
        end
    end

    local function CreateRow(parent, i)
        local row = CreateFrame("Button", nil, parent)
        row:SetSize(FRAME_W - 40, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        -- Zebra stripe (stable per slot) + bottom hairline, drawn under the highlight
        row.zebra = row:CreateTexture(nil, "BACKGROUND")
        row.zebra:SetAllPoints()
        row.zebra:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.025 or 0.0)

        row.bottomLine = row:CreateTexture(nil, "ARTWORK")
        row.bottomLine:SetHeight(1)
        row.bottomLine:SetPoint("BOTTOMLEFT", 4, 0)
        row.bottomLine:SetPoint("BOTTOMRIGHT", -4, 0)
        row.bottomLine:SetColorTexture(1, 1, 1, 0.05)

        row.hl = row:CreateTexture(nil, "HIGHLIGHT")
        row.hl:SetAllPoints()
        row.hl:SetColorTexture(1, 1, 1, 0.08)

        -- Faction chip (H/A/?)
        row.factionChip = CreateChip(row, 18, 18, 9)
        row.factionChip:SetPoint("LEFT", 4, 0)

        -- Name
        row.name = row:CreateFontString(nil, "OVERLAY")
        row.name:SetFont(FONT, 11)
        row.name:SetPoint("LEFT", row.factionChip, "RIGHT", 4, 0)
        row.name:SetWidth(100)
        row.name:SetJustifyH("LEFT")

        -- Bracket pill
        row.bracketPill = CreateChip(row, 50, 18, 9)
        row.bracketPill:SetPoint("LEFT", row.name, "RIGHT", 4, 0)

        -- [WG+] addon-detected badge (hidden when not applicable)
        row.wgBadge = CreateChip(row, 30, 18, 8)
        row.wgBadge:SetPoint("LEFT", row.bracketPill, "RIGHT", 4, 0)

        -- Note (flex) — anchored at a fixed offset so hiding the WG+ badge never shifts it
        row.note = row:CreateFontString(nil, "OVERLAY")
        row.note:SetFont(FONT, 10)
        row.note:SetPoint("LEFT", 220, 0)
        row.note:SetPoint("RIGHT", row, "RIGHT", -100, 0)
        row.note:SetJustifyH("LEFT")
        row.note:SetTextColor(0.7, 0.7, 0.7, 1)

        -- Head-to-head (W-L vs this poster, if records exist)
        row.h2h = row:CreateFontString(nil, "OVERLAY")
        row.h2h:SetFont(FONT, 10, "OUTLINE")
        row.h2h:SetPoint("RIGHT", row, "RIGHT", -56, 0)
        row.h2h:SetWidth(40)
        row.h2h:SetJustifyH("RIGHT")

        -- Age (rightmost)
        row.age = row:CreateFontString(nil, "OVERLAY")
        row.age:SetFont(FONT, 10)
        row.age:SetPoint("RIGHT", -6, 0)
        row.age:SetWidth(48)
        row.age:SetJustifyH("RIGHT")
        row.age:SetTextColor(0.6, 0.6, 0.6, 1)

        row:SetScript("OnClick", RowClicked)
        return row
    end

    function f:Refresh()
        SweepExpired()
        local now = time()

        -- Community hint banner visibility: only when community is not detected
        -- AND the user hasn't dismissed it AND they're viewing the live list.
        local showHint = (not communityTarget)
            and (not WG_History.lfgCommunityHintDismissed)
            and (viewMode == "live")
        f.hintBanner:SetShown(showHint)
        f.PositionScroll()

        -- Reach footer: composes available transports into "guild · WargamesPlus community"
        local parts = {}
        if IsInGuild() then table.insert(parts, L["LFG_REACH_GUILD"]) end
        if communityTarget then table.insert(parts, L["LFG_REACH_COMMUNITY"]) end
        if #parts == 0 then
            f.reachText:SetText(L["LFG_REACH_LABEL"] .. " |cffff7777none|r")
        else
            f.reachText:SetText(L["LFG_REACH_LABEL"] .. " " .. table.concat(parts, " · "))
        end

        -- Source list depends on view mode
        local rows
        if viewMode == "history" then
            rows = GetHistoryRows()
        else
            rows = WG.LFG_GetPosts()
        end

        -- Apply filters (bracket, faction, search)
        local filtered = {}
        for i = 1, #rows do
            if PassesFilter(rows[i]) then
                table.insert(filtered, rows[i])
            end
        end

        -- Header / footer text
        if myPost then
            postBtn:SetText(L["LFG_UNPOST"])
            local minsLeft = math.max(0, math.floor(((myPost.expiresAt or now) - now) / 60))
            f.statusText:SetText(string.format(L["LFG_EXPIRES_IN"], minsLeft))
        else
            postBtn:SetText(L["LFG_POST"])
            f.statusText:SetText("")
        end
        f.footerText:SetText(string.format("%d / %d", #filtered, #rows))

        -- Grow or reuse rows
        for i = 1, #filtered do
            local row = f.rows[i]
            if not row then
                row = CreateRow(scrollChild, i)
                f.rows[i] = row
            end
            local p = filtered[i]
            row.postData = p

            -- Zebra stripe: subtle accent tint for your own listing, plain zebra otherwise
            if p.isSelf then
                local sa = WG.GetActiveTheme().accent
                row.zebra:SetColorTexture(sa[1], sa[2], sa[3], 0.12)
            else
                row.zebra:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.025 or 0.0)
            end

            -- Faction chip
            if p.faction == "H" then
                -- WG.FACTION_COLORS: fixed (not theme-driven) so Horde/Alliance stay
                -- recognizable red/blue regardless of the addon's active UI theme
                local hc = WG.FACTION_COLORS.Horde
                row.factionChip:SetBackdropColor(hc[1], hc[2], hc[3], 0.55)
                row.factionChip:SetBackdropBorderColor(hc[1], hc[2], hc[3], 0.8)
                row.factionChip.text:SetText("H")
            elseif p.faction == "A" then
                local ac = WG.FACTION_COLORS.Alliance
                row.factionChip:SetBackdropColor(ac[1], ac[2], ac[3], 0.55)
                row.factionChip:SetBackdropBorderColor(ac[1], ac[2], ac[3], 0.8)
                row.factionChip.text:SetText("A")
            else
                row.factionChip:SetBackdropColor(0.25, 0.25, 0.28, 0.7)
                row.factionChip:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.4)
                row.factionChip.text:SetText("?")
            end
            row.factionChip.text:SetTextColor(1, 1, 1, 0.95)

            row.name:SetText(p.poster or "")

            -- Bracket pill, tinted with the active theme's accent color
            local acc = WG.GetActiveTheme().accent
            row.bracketPill:SetBackdropColor(acc[1], acc[2], acc[3], 0.18)
            row.bracketPill:SetBackdropBorderColor(acc[1], acc[2], acc[3], 0.5)
            row.bracketPill.text:SetText(BRACKET_LABEL[p.bracket] or p.bracket or "")
            row.bracketPill.text:SetTextColor(0.92, 0.92, 0.96, 1)

            -- [WG+] badge: "YOU" for your own listing, otherwise shown only when the
            -- poster is confirmed to have the addon
            local hasBadge = HasAddonBadge(p.poster, p.realm)
            row.wgBadge:SetShown(p.isSelf or hasBadge)
            if p.isSelf then
                row.wgBadge:SetBackdropColor(0.20, 0.55, 0.25, 0.35)
                row.wgBadge:SetBackdropBorderColor(0.35, 0.90, 0.40, 0.8)
                row.wgBadge.text:SetText(L["LFG_YOU"])
                row.wgBadge.text:SetTextColor(1, 1, 1, 1)
            elseif hasBadge then
                row.wgBadge:SetBackdropColor(acc[1], acc[2], acc[3], 0.30)
                row.wgBadge:SetBackdropBorderColor(acc[1], acc[2], acc[3], 0.8)
                row.wgBadge.text:SetText("WG+")
                row.wgBadge.text:SetTextColor(1, 1, 1, 1)
            end

            row.note:SetText(p.note or "")

            local w, losses = HeadToHead(p.poster)
            if w + losses > 0 then
                local color = (w > losses and "|cff77ff77") or (w < losses and "|cffff7777") or "|cffcccccc"
                row.h2h:SetText(color .. string.format(L["LFG_HEAD_TO_HEAD"], w, losses) .. "|r")
            else
                row.h2h:SetText("")
            end

            row.age:SetText(AgeString(now - (p.lastSeen or now)))
            row:Show()
        end
        -- Hide unused rows
        for i = #filtered + 1, #f.rows do
            f.rows[i]:Hide()
        end
        scrollChild:SetHeight(math.max(10, #filtered * ROW_HEIGHT))

        -- Empty state
        if #filtered == 0 then
            if not f.emptyText then
                f.emptyText = scrollChild:CreateFontString(nil, "OVERLAY")
                f.emptyText:SetFont(FONT, 11)
                f.emptyText:SetPoint("TOP", 0, -20)
                f.emptyText:SetTextColor(0.65, 0.65, 0.65, 1)
            end
            f.emptyText:SetText(L["LFG_NO_POSTS"])
            f.emptyText:Show()
        elseif f.emptyText then
            f.emptyText:Hide()
        end
    end

    lfgFrame = f
    f:Hide()  -- Start hidden so ToggleLFGFrame's IsShown() check correctly opens it on first click
    return f
end

function WG.ToggleLFGFrame()
    if not WG.mainFrame then return end
    if not lfgFrame then BuildFrame() end
    if not lfgFrame then return end
    if lfgFrame:IsShown() then
        lfgFrame:Hide()
    else
        if WG.CloseSecondaryWindows then WG.CloseSecondaryWindows("WG_LFGFrame") end
        lfgFrame:Show()
        lfgFrame:Refresh()
    end
end

function WG.HideLFGFrame()
    if lfgFrame and lfgFrame:IsShown() then lfgFrame:Hide() end
end

-- ============================================================
-- Events
-- ============================================================
local ef = CreateFrame("Frame")
ef:RegisterEvent("PLAYER_LOGIN")
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("CHAT_MSG_ADDON")
ef:RegisterEvent("CHAT_MSG_COMMUNITIES_CHANNEL")
ef:RegisterEvent("CLUB_ADDED")
ef:RegisterEvent("CLUB_REMOVED")
ef:RegisterEvent("INITIAL_CLUBS_LOADED")
ef:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2.0, DetectCommunity)
    elseif event == "CLUB_ADDED" or event == "CLUB_REMOVED" or event == "INITIAL_CLUBS_LOADED" then
        -- User joined/left/loaded streams for a community — recheck
        DetectCommunity()
        if lfgFrame and lfgFrame:IsShown() and lfgFrame.Refresh then
            lfgFrame:Refresh()
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, senderFull = ...
        if prefix == ADDON_PREFIX and channel == "GUILD" then
            HandleIncoming(msg, senderFull)
        end
    elseif event == "CHAT_MSG_COMMUNITIES_CHANNEL" then
        -- arg9 (channelBaseName) has the format "Community:<clubId>:<streamId>"
        local msg, senderFull = select(1, ...)
        local channelBaseName = select(9, ...)
        if not communityTarget or not channelBaseName then return end
        local clubId, streamId = channelBaseName:match("^Community:(%d+):(%d+)$")
        if clubId == tostring(communityTarget.clubId)
                and streamId == tostring(communityTarget.streamId) then
            HandleIncoming(msg, senderFull)
        end
    end
end)

-- Periodic expiry sweep while UI is open
C_Timer.NewTicker(30, function()
    if lfgFrame and lfgFrame:IsShown() then SweepExpired() end
end)
