-- tracker.lua: WarGames+ Win/Loss Tracker

local WG = _G["WargamesPlus"]
if not WG then return end
local L = WG.L or setmetatable({}, { __index = function(_, k) return tostring(k) end })

local MAX_RECORDS = 200
local CHALLENGE_EXPIRY = 3600 -- 1 hour
local FONT = WG.ADDON_FONT

-- Guards match recording: WG.lastChallenge lingers for up to CHALLENGE_EXPIRY
-- after a challenge is sent, so without a check a normal queued match (e.g. a
-- rated solo shuffle) that ends inside that window would be logged as a wargame.
--
-- IsWargame() is used as a *positive* signal only (true => definitely record) and
-- the rated-queue APIs as a *negative* signal (true => definitely a real queued
-- match, skip). When neither is conclusive we fall back to the pre-4.2.1
-- freshness heuristic (a live WG.lastChallenge inside the expiry window) rather
-- than dropping the record — IsWargame() is unreliable / returns false for some
-- wargame types (notably solo shuffle & blitz wargames), so a hard `false` here
-- silently stops all tracking for those modes.
local function CompletedMatchIsWargame()
    if type(IsWargame) == "function" then
        local ok, res = pcall(IsWargame)
        if ok and res then return true end
    end
    if C_PvP then
        if C_PvP.IsRatedSoloShuffle and C_PvP.IsRatedSoloShuffle() then return false end
        if C_PvP.IsRatedSoloRBG and C_PvP.IsRatedSoloRBG() then return false end
        if C_PvP.IsRatedMap and C_PvP.IsRatedMap() then return false end
        if C_PvP.IsRatedBattleground and C_PvP.IsRatedBattleground() then return false end
    end
    return true -- inconclusive — trust the live challenge rather than drop a real record
end
local MIN_PANEL_WIDTH = 300
local MAX_PANEL_WIDTH = 500
local WIDTH_PADDING   = 60

-- ---------- NEMESIS / RIVAL MESSAGES ----------
local NEMESIS_MESSAGES = {
    "[Name] owns you and you both know it.",
    "At this point [Name] is just farming you.",
    "[Name] sends their regards... again.",
    "You are [Name]'s favorite punching bag.",
    "[Name] didn't even have to try that time.",
    "Somewhere, [Name] is laughing at you.",
    "[Name] has your number. And your lunch money.",
    "That's another one for [Name]'s highlight reel.",
    "[Name] could beat you in their sleep at this point.",
    "You sure you want to keep queuing into [Name]?",
    "[Name] is living rent-free in your head.",
    "Another day, another loss to [Name].",
    "[Name] just added another chapter to your tragedy.",
    "Your grandchildren will hear tales of how [Name] destroyed you.",
    "[Name] is starting to feel bad for you. Almost.",
}

local RIVAL_MESSAGES = {
    "[Name] never stood a chance.",
    "You just reminded [Name] why they should reroll.",
    "[Name] is punching air right now.",
    "Add that to [Name]'s therapy bill.",
    "[Name] is typing something angry right now.",
    "You own [Name] and everyone knows it.",
    "[Name] should just /afk when they see your name.",
    "Another win against [Name]. Like clockwork.",
    "[Name] keeps coming back for more punishment.",
    "At this point [Name] is just a free win.",
    "Somewhere, [Name] is blaming their healer.",
    "[Name]'s losing streak against you continues.",
    "You are [Name]'s final boss and they can't clear it.",
    "[Name] might want to consider a different game.",
    "That was barely even a warmup against [Name].",
}

local BEAT_NEMESIS_MESSAGES = {
    "You beat your nemesis [Name]. The curse is broken.",
    "Nemesis [Name] defeated. That had to feel good.",
    "You finally beat your nemesis [Name]. Mark the calendar.",
    "Nemesis [Name] goes down. The prophecy has been fulfilled.",
    "You defeated your nemesis [Name]. Balance has been restored.",
    "Nemesis [Name] has fallen. Miracles do happen.",
    "You beat your nemesis [Name]. That scoreboard just got interesting.",
    "Nemesis [Name] defeated. Revenge looks good on you.",
    "You dropped your nemesis [Name]. Worth the wait.",
    "Nemesis [Name] just lost to you. That had to sting.",
    "You defeated your nemesis [Name]. Redemption achieved.",
    "Nemesis [Name] goes down. The rivalry just got spicy.",
    "You beat your nemesis [Name]. The tables have officially turned.",
    "Nemesis [Name] defeated. Enjoy the moment.",
    "You defeated [Name]. Your nemesis might want a rematch.",
}

local LOST_TO_RIVAL_MESSAGES = {
    "You lost to rival [Name]. Don't let them get used to it.",
    "Rival [Name] beat you this time. Try not to encourage them.",
    "You lost to your rival [Name]. They're going to talk about this.",
    "Rival [Name] wins this round. That's... unusual.",
    "You lost to [Name]. Your rival will not let you forget it.",
    "Rival [Name] got the win. Expect bragging shortly.",
    "You lost to rival [Name]. They'll be insufferable now.",
    "Rival [Name] beat you. The upset of the day.",
    "You lost to [Name]. Rival [Name] is going to enjoy that.",
    "Rival [Name] wins this one. Try not to make it a pattern.",
    "You lost to rival [Name]. They're definitely screenshotting that.",
    "Rival [Name] beat you. That one's going on their highlight reel.",
    "You lost to [Name]. Your rival finally got one back.",
    "Rival [Name] takes the win. That ego just leveled up.",
    "You lost to rival [Name]. Don't worry, the rematch is coming.",
}

local nemesisMsgOrder, nemesisMsgIndex = {}, 0
local rivalMsgOrder, rivalMsgIndex = {}, 0
local beatNemesisMsgOrder, beatNemesisMsgIndex = {}, 0
local lostToRivalMsgOrder, lostToRivalMsgIndex = {}, 0

local function ShuffleOrder(order, count)
    for i = 1, count do order[i] = i end
    for i = count, 2, -1 do
        local j = math.random(1, i)
        order[i], order[j] = order[j], order[i]
    end
end

local function GetNextMessage(messages, order, idx)
    local count = #messages
    if idx == 0 or idx > count then
        ShuffleOrder(order, count)
        idx = 1
    end
    local msg = messages[order[idx]]
    return msg, idx + 1
end

-- ---------- LOCAL STATE ----------
local statsFrame
local profileCard
local activeTab = "opponents" -- "opponents" | "maps" | "log" | "session"
local pendingResult = false
local ShowProfileCard -- forward declaration
local recapPopup, noteEditor -- lazily created uikit text popups

-- ---------- HELPERS ----------
local function GetRecords()
    if not WG_History.records then WG_History.records = {} end
    return WG_History.records
end

local function GetRealRecords()
    local all = GetRecords()
    local real = {}
    for _, rec in ipairs(all) do
        if not rec.debug then
            real[#real + 1] = rec
        end
    end
    return real
end

local function GetNemesisRivalNames()
    local records = GetRealRecords()
    local tally = {}
    for _, r in ipairs(records) do
        local opp = r.opponent
        if opp then
            if not tally[opp] then tally[opp] = { w = 0, l = 0, total = 0 } end
            tally[opp].total = tally[opp].total + 1
            if r.result == "win" then
                tally[opp].w = tally[opp].w + 1
            elseif r.result == "loss" then
                tally[opp].l = tally[opp].l + 1
            end
        end
    end
    local nemesis, rival
    local mostLosses, mostWins = 0, 0
    for name, t in pairs(tally) do
        if t.total >= 3 and t.l > mostLosses then
            mostLosses = t.l
            nemesis = name
        end
        if t.total >= 3 and t.w > mostWins then
            mostWins = t.w
            rival = name
        end
    end
    return nemesis, rival
end

local function TimeAgo(ts)
    local diff = time() - ts
    if diff < 60 then return string.format(L["TIME_SECONDS_AGO"], diff) end
    if diff < 3600 then return string.format(L["TIME_MINUTES_AGO"], math.floor(diff / 60)) end
    if diff < 86400 then return string.format(L["TIME_HOURS_AGO"], math.floor(diff / 3600)) end
    return string.format(L["TIME_DAYS_AGO"], math.floor(diff / 86400))
end

local function WinColor(text)
    local t = WG.GetActiveTheme()
    return "|cff" .. t.inlineGreen .. text .. "|r"
end

local function LossColor(text)
    local t = WG.GetActiveTheme()
    return "|cff" .. (t.inlineLoss or "ff4444") .. text .. "|r"
end

local function DrawColor(text)
    return "|cffaaaaaa" .. text .. "|r"
end

local function AccentColor(text)
    local t = WG.GetActiveTheme()
    return "|cff" .. t.inlineAccent .. text .. "|r"
end

local function CharColor(text)
    local t = WG.GetActiveTheme()
    return "|cff" .. t.inlineChar .. text .. "|r"
end

local function ClassColoredName(name, classToken)
    if not classToken or not RAID_CLASS_COLORS or not RAID_CLASS_COLORS[classToken] then
        return name or "Unknown"
    end
    local cc = RAID_CLASS_COLORS[classToken]
    return ("|cff%02x%02x%02x%s|r"):format(cc.r * 255, cc.g * 255, cc.b * 255, name)
end

local function FormatNumber(n)
    if not n then return "0" end
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    end
    return tostring(n)
end

local function GetStreakInfo()
    local records = GetRealRecords()
    if #records == 0 then return nil, 0, nil, 0 end

    -- Current streak (records are newest-first)
    local currentType = records[1].result
    local currentLen = 0
    for _, rec in ipairs(records) do
        if rec.result == currentType then
            currentLen = currentLen + 1
        else
            break
        end
    end

    -- Best-ever streaks
    local bestWin, bestLoss = 0, 0
    local streak = 0
    local lastResult = nil
    for _, rec in ipairs(records) do
        if rec.result == lastResult then
            streak = streak + 1
        else
            streak = 1
            lastResult = rec.result
        end
        if lastResult == "win" and streak > bestWin then bestWin = streak end
        if lastResult == "loss" and streak > bestLoss then bestLoss = streak end
    end

    local bestType, bestLen
    if bestWin >= bestLoss then
        bestType = "win"
        bestLen = bestWin
    else
        bestType = "loss"
        bestLen = bestLoss
    end

    return currentType, currentLen, bestType, bestLen
end

-- ---------- NAME HELPERS ----------
local function NormalizeName(name)
    if not name then return nil end
    return name:match("^([^-]+)") or name
end

local function NamesMatch(a, b)
    if not a or not b then return false end
    if a == b then return true end
    return NormalizeName(a) == NormalizeName(b)
end

-- ---------- DATA AGGREGATION ----------
local function GetOpponentStats()
    local stats = {}
    for _, rec in ipairs(GetRealRecords()) do
        local key = NormalizeName(rec.opponent) or rec.opponent
        if not stats[key] then
            stats[key] = {wins = 0, losses = 0, draws = 0}
        end
        local s = stats[key]
        if rec.result == "win" then s.wins = s.wins + 1
        elseif rec.result == "loss" then s.losses = s.losses + 1
        else s.draws = s.draws + 1 end
    end
    local sorted = {}
    for name, s in pairs(stats) do
        s.name = name
        s.total = s.wins + s.losses + s.draws
        s.pct = s.total > 0 and math.floor((s.wins / s.total) * 100) or 0
        table.insert(sorted, s)
    end
    table.sort(sorted, function(a, b) return a.total > b.total end)
    return sorted
end

local function GetMapStats()
    local stats = {}
    for _, rec in ipairs(GetRealRecords()) do
        if not stats[rec.map] then
            stats[rec.map] = {wins = 0, losses = 0, draws = 0}
        end
        local s = stats[rec.map]
        if rec.result == "win" then s.wins = s.wins + 1
        elseif rec.result == "loss" then s.losses = s.losses + 1
        else s.draws = s.draws + 1 end
    end
    local sorted = {}
    for name, s in pairs(stats) do
        s.name = name
        s.total = s.wins + s.losses + s.draws
        s.pct = s.total > 0 and math.floor((s.wins / s.total) * 100) or 0
        table.insert(sorted, s)
    end
    table.sort(sorted, function(a, b) return a.total > b.total end)
    return sorted
end

local function GetOpponentProfile(opponentName)
    if not opponentName then return nil end
    local records = GetRealRecords()
    local wins, losses, draws = 0, 0, 0
    local matches = {}
    for _, rec in ipairs(records) do
        if NamesMatch(rec.opponent, opponentName) then
            if rec.result == "win" then wins = wins + 1
            elseif rec.result == "loss" then losses = losses + 1
            else draws = draws + 1 end
            table.insert(matches, rec)
        end
    end
    local total = wins + losses + draws
    if total == 0 then return nil end
    local pct = math.floor((wins / total) * 100)

    -- Current streak vs this opponent
    local streak, streakType = 0, nil
    for _, rec in ipairs(matches) do
        if streakType == nil then
            streakType = rec.result
            streak = 1
        elseif rec.result == streakType then
            streak = streak + 1
        else
            break
        end
    end

    return {
        name = opponentName,
        wins = wins, losses = losses, draws = draws,
        total = total, pct = pct,
        streak = streak, streakType = streakType,
        matches = matches,
    }
end

local function GetOverallStats()
    local w, l, d = 0, 0, 0
    for _, rec in ipairs(GetRealRecords()) do
        if rec.result == "win" then w = w + 1
        elseif rec.result == "loss" then l = l + 1
        else d = d + 1 end
    end
    local total = w + l + d
    local pct = total > 0 and math.floor((w / total) * 100) or 0
    return w, l, d, total, pct
end

local function GetTodayStats()
    local w, l, d = 0, 0, 0
    local now = time()
    local lt = date("*t")
    local today = now - (lt.hour * 3600 + lt.min * 60 + lt.sec)
    for _, rec in ipairs(GetRealRecords()) do
        if rec.timestamp < today then break end
        if rec.result == "win" then w = w + 1
        elseif rec.result == "loss" then l = l + 1
        else d = d + 1 end
    end
    return w, l, d, w + l + d
end

-- ---------- SESSION STATS ----------
local SESSION_GAP = 120 * 60  -- auto-boundary: a gap longer than this ends the session

-- Records for the current session, newest-first. Manual override (WG_History.
-- sessionOverride.active) wins; otherwise walk back from the latest match until a
-- gap longer than SESSION_GAP.
local function GetSessionRecords()
    local real = GetRealRecords()
    local out = {}
    local ov = WG_History.sessionOverride
    if ov and ov.active then
        for _, r in ipairs(real) do
            if r.timestamp >= (ov.startTime or 0) then out[#out + 1] = r else break end
        end
        return out
    end
    local prev
    for _, r in ipairs(real) do
        if prev and (prev - r.timestamp) > SESSION_GAP then break end
        out[#out + 1] = r
        prev = r.timestamp
    end
    return out
end

local function GetSessionSummary()
    local recs = GetSessionRecords()
    local s = { total = 0, w = 0, l = 0, d = 0, pct = 0,
                byMode = {}, modeOrder = {}, byMap = {}, mapOrder = {},
                byOpp = {}, oppOrder = {},
                startTime = recs[#recs] and recs[#recs].timestamp or nil,
                endTime = recs[1] and recs[1].timestamp or nil }
    local function bump(bucket, order, key, res)
        if not key or key == "" then return end
        local e = bucket[key]
        if not e then e = { w = 0, l = 0, d = 0 }; bucket[key] = e; order[#order + 1] = key end
        if res == "win" then e.w = e.w + 1 elseif res == "loss" then e.l = e.l + 1 else e.d = e.d + 1 end
    end
    for _, r in ipairs(recs) do
        s.total = s.total + 1
        if r.result == "win" then s.w = s.w + 1
        elseif r.result == "loss" then s.l = s.l + 1
        else s.d = s.d + 1 end
        bump(s.byMode, s.modeOrder, r.matchType, r.result)
        bump(s.byMap, s.mapOrder, r.map, r.result)
        bump(s.byOpp, s.oppOrder, NormalizeName(r.opponent) or r.opponent, r.result)
    end
    s.pct = s.total > 0 and math.floor((s.w / s.total) * 100) or 0
    -- top opponent = most games played (tie-break: most wins)
    local topKey, topGames, topWins
    for key, e in pairs(s.byOpp) do
        local g = e.w + e.l + e.d
        if not topKey or g > topGames or (g == topGames and e.w > topWins) then
            topKey, topGames, topWins = key, g, e.w
        end
    end
    s.topOpp = topKey
    return s
end

-- Duration string: "2h 14m" / "43m"
local function FormatSpan(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    if h > 0 then return string.format("%dh %02dm", h, m) end
    return string.format("%dm", m)
end

-- The veto (from WG_History.vetoHistory) that most likely produced this match: same
-- opponent, timestamp within [match - 2h, match + 5m], closest to the match.
local function GetVetoForRecord(rec)
    if not rec or not WG_History.vetoHistory then return nil end
    local want = NormalizeName(rec.opponent)
    local best, bestGap
    for oppKey, entries in pairs(WG_History.vetoHistory) do
        if NormalizeName(oppKey) == want then
            for _, e in ipairs(entries) do
                local gap = rec.timestamp - (e.timestamp or 0)
                if gap >= -300 and gap <= SESSION_GAP and (not bestGap or math.abs(gap) < bestGap) then
                    best, bestGap = e, math.abs(gap)
                end
            end
        end
    end
    return best
end

-- ---------- OPPONENT RESOLUTION ----------
local function ResolveOpponent(challenge, players, playerFaction)
    if not challenge.initiator then return challenge.opponent end

    if players and #players > 0 and playerFaction ~= nil then
        local initName = (challenge.initiator or ""):match("^([^-]+)") or ""
        for _, p in ipairs(players) do
            local pName = p.name and p.name:match("^([^-]+)") or ""
            if pName == initName then
                if p.faction == playerFaction then
                    return challenge.opponent
                else
                    return challenge.initiator
                end
            end
        end
    end

    local myName = UnitName("player")
    if myName == challenge.initiator then
        return challenge.opponent
    elseif myName == challenge.opponent then
        return challenge.initiator
    end

    return challenge.opponent
end

-- ---------- MATCH RESULT DETECTION ----------
local eventFrame = CreateFrame("Frame")

local MODE_LABELS = {
    ARENA_2V2    = L["MODE_LABEL_2V2"],
    ARENA_3V3    = L["MODE_LABEL_3V3"],
    ARENA_5V5    = L["MODE_LABEL_5V5"],
    SOLO_SHUFFLE = L["MODE_LABEL_SOLO_SHUFFLE"],
    BG           = L["MODE_LABEL_BG"],
    BLITZ        = L["MODE_LABEL_BLITZ"],
}

local function RecordMatch(result, players, playerName)
    if WG_History.trackMatches == false then return end
    local challenge = WG.lastChallenge
    if not challenge then return end

    local matchType = MODE_LABELS[challenge.matchSize] or challenge.matchSize or "Unknown"

    local record = {
        opponent   = challenge.opponent,
        map        = challenge.map,
        result     = result,
        matchType  = matchType,
        duration   = time() - challenge.timestamp,
        timestamp  = time(),
        players    = players,
        playerName = playerName,
        debug      = challenge.debug or nil,
    }

    local records = GetRecords()
    table.insert(records, 1, record)
    local maxRec = WG_History.maxRecords or MAX_RECORDS
    if #records > maxRec then
        table.remove(records)
    end

    WG.lastChallenge = nil
    WG_History.lastChallenge = nil

    local resultText
    if result == "win" then resultText = WinColor(L["WIN"])
    elseif result == "loss" then resultText = LossColor(L["LOSS"])
    else resultText = DrawColor(L["DRAW"]) end

    if WG_History.showMatchChat ~= false then
        print(AccentColor(L["CHAT_PREFIX"]) .. " " .. string.format(L["MSG_MATCH_RESULT"], resultText, CharColor(record.opponent), record.map))
    end

    -- Nemesis / Rival themed messages
    if WG_History.showNemesisChat ~= false then
        local nemesisName, rivalName = GetNemesisRivalNames()
        local PREFIX = AccentColor(L["CHAT_PREFIX"])
        local DIVIDER = AccentColor("------------------------------")
        if nemesisName and record.opponent == nemesisName then
            local msg, tag
            if result == "loss" then
                msg, nemesisMsgIndex = GetNextMessage(NEMESIS_MESSAGES, nemesisMsgOrder, nemesisMsgIndex)
                msg = msg:gsub("%[Name%]", LossColor(record.opponent))
                tag = LossColor("!! NEMESIS !!")
            elseif result == "win" then
                msg, beatNemesisMsgIndex = GetNextMessage(BEAT_NEMESIS_MESSAGES, beatNemesisMsgOrder, beatNemesisMsgIndex)
                msg = msg:gsub("%[Name%]", WinColor(record.opponent))
                tag = WinColor("!! NEMESIS DOWN !!")
            end
            if msg then
                print(PREFIX .. " " .. DIVIDER)
                print(PREFIX .. "  " .. tag .. "  " .. msg)
                print(PREFIX .. " " .. DIVIDER)
            end
        elseif rivalName and record.opponent == rivalName then
            local msg, tag
            if result == "win" then
                msg, rivalMsgIndex = GetNextMessage(RIVAL_MESSAGES, rivalMsgOrder, rivalMsgIndex)
                msg = msg:gsub("%[Name%]", WinColor(record.opponent))
                tag = WinColor(">> RIVAL CRUSHED <<")
            elseif result == "loss" then
                msg, lostToRivalMsgIndex = GetNextMessage(LOST_TO_RIVAL_MESSAGES, lostToRivalMsgOrder, lostToRivalMsgIndex)
                msg = msg:gsub("%[Name%]", LossColor(record.opponent))
                tag = LossColor(">> RIVAL UPSET <<")
            end
            if msg then
                print(PREFIX .. " " .. DIVIDER)
                print(PREFIX .. "  " .. tag .. "  " .. msg)
                print(PREFIX .. " " .. DIVIDER)
            end
        end
    end

    if statsFrame and statsFrame:IsShown() then
        statsFrame:RefreshContent()
    end
end

local pendingWinner = nil

local function ProcessMatchScores(winner)
    if not pendingResult then return end
    if not WG.lastChallenge then pendingResult = false return end

    local numScores = GetNumBattlefieldScores()
    if numScores == 0 then return false end

    local playerGUID = UnitGUID("player")
    local playerFaction
    local playerRoundsWon
    local players = {}

    local isShuffle = WG.lastChallenge and WG.lastChallenge.matchSize == "SOLO_SHUFFLE"

    for i = 1, numScores do
        local info = C_PvP.GetScoreInfo(i)
        if info then
            local playerEntry = {
                name       = info.name,
                classToken = info.classToken,
                faction    = info.faction,
                damage     = info.damageDone or 0,
                healing    = info.healingDone or 0,
                kills      = info.killingBlows or 0,
                deaths     = info.deaths or 0,
            }

            if isShuffle and info.stats then
                for _, stat in ipairs(info.stats) do
                    if stat.name and stat.name:lower():find("rounds") then
                        playerEntry.roundsWon = stat.value or 0
                        break
                    end
                end
            end

            table.insert(players, playerEntry)
            if info.guid == playerGUID then
                playerFaction = info.faction
                if isShuffle then
                    playerRoundsWon = playerEntry.roundsWon
                end
            end
        end
    end

    pendingResult = false
    pendingWinner = nil
    local pName = UnitName("player")

    WG.lastChallenge.opponent = ResolveOpponent(WG.lastChallenge, players, playerFaction)

    if playerFaction == nil then
        RecordMatch("draw", players, pName)
        return true
    end

    -- Solo Shuffle: determine result by individual rounds won, not faction winner
    if isShuffle and playerRoundsWon then
        if playerRoundsWon >= 4 then RecordMatch("win", players, pName)
        elseif playerRoundsWon == 3 then RecordMatch("draw", players, pName)
        else RecordMatch("loss", players, pName) end
    elseif winner == 0 and playerFaction == 0 then RecordMatch("win", players, pName)
    elseif winner == 1 and playerFaction == 1 then RecordMatch("win", players, pName)
    elseif winner == 255 then RecordMatch("draw", players, pName)
    else RecordMatch("loss", players, pName) end

    if WG.BroadcastMatchResult then
        WG.BroadcastMatchResult(winner)
    end

    return true
end

local function OnPvpMatchComplete(_, winner)
    if not WG.lastChallenge then return end

    local elapsed = time() - WG.lastChallenge.timestamp
    if elapsed > CHALLENGE_EXPIRY then
        WG.lastChallenge = nil
        WG_History.lastChallenge = nil
        return
    end

    -- A challenge is still pending but this match isn't the wargame — a normal
    -- queued match finished first. Leave lastChallenge intact for the real one.
    if not CompletedMatchIsWargame() then return end

    pendingResult = true
    pendingWinner = winner
    C_Timer.After(0.5, function()
        if not pendingResult then return end
        local numScores = GetNumBattlefieldScores()
        if numScores == 0 then
            RequestBattlefieldScoreData()
            return
        end
        ProcessMatchScores(winner)
    end)
end

local function OnUpdateBattlefieldScore()
    if not pendingResult then return end
    if not WG.lastChallenge then pendingResult = false return end

    local numScores = GetNumBattlefieldScores()
    if numScores == 0 then return end

    ProcessMatchScores(pendingWinner)
end

eventFrame:RegisterEvent("PVP_MATCH_COMPLETE")
eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PVP_MATCH_COMPLETE" then
        OnPvpMatchComplete(self, ...)
    elseif event == "UPDATE_BATTLEFIELD_SCORE" then
        OnUpdateBattlefieldScore()
    end
end)

-- ---------- RELOAD RECOVERY ----------
function WG.AttemptReloadRecovery()
    if not WG.lastChallenge then return end
    local elapsed = time() - (WG.lastChallenge.timestamp or 0)
    if elapsed > CHALLENGE_EXPIRY then
        WG.lastChallenge = nil
        WG_History.lastChallenge = nil
        return
    end
    if not CompletedMatchIsWargame() then return end
    pendingResult = true

    local bfWinner = GetBattlefieldWinner()
    if bfWinner then
        pendingWinner = bfWinner
    end

    C_Timer.After(1, function()
        if not pendingResult then return end
        local numScores = GetNumBattlefieldScores()
        if numScores > 0 and pendingWinner ~= nil then
            ProcessMatchScores(pendingWinner)
        else
            RequestBattlefieldScoreData()
        end
    end)
end

-- ---------- MATCH SYNC HANDLER (from party broadcast) ----------
function WG.OnMatchSyncReceived(sender, winner)
    if not pendingResult then return end
    if not WG.lastChallenge then return end
    local elapsed = time() - (WG.lastChallenge.timestamp or 0)
    if elapsed > CHALLENGE_EXPIRY then
        WG.lastChallenge = nil
        WG_History.lastChallenge = nil
        pendingResult = false
        return
    end

    local numScores = GetNumBattlefieldScores()
    if numScores > 0 then
        ProcessMatchScores(winner)
        return
    end

    pendingResult = false
    pendingWinner = nil
    local pName = UnitName("player")
    local playerFaction = UnitFactionGroup("player") == "Horde" and 0 or 1

    WG.lastChallenge.opponent = ResolveOpponent(WG.lastChallenge, {}, nil)

    local result
    if winner == playerFaction then result = "win"
    elseif winner == 255 then result = "draw"
    else result = "loss" end

    RecordMatch(result, {}, pName)
end

-- ---------- UI HELPERS ----------
local function CreateAccentStripe(parent)
    local stripe = parent:CreateTexture(nil, "ARTWORK")
    stripe:SetHeight(2)
    stripe:SetPoint("TOPLEFT", 1, -1)
    stripe:SetPoint("TOPRIGHT", -1, -1)
    local t = WG.GetActiveTheme()
    stripe:SetColorTexture(t.accent[1], t.accent[2], t.accent[3], 0.8)
    WG.RegisterThemedElement(stripe, function(tex)
        local th = WG.GetActiveTheme()
        tex:SetColorTexture(th.accent[1], th.accent[2], th.accent[3], 0.8)
    end)
    return stripe
end

local function CreateSeparator(parent, yOffset)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", 10, 0)
    line:SetPoint("RIGHT", -10, 0)
    line:SetPoint("TOP", 0, yOffset)
    local t = WG.GetActiveTheme()
    line:SetColorTexture(t.accent[1], t.accent[2], t.accent[3], 0.2)
    WG.RegisterThemedElement(line, function(tex)
        local th = WG.GetActiveTheme()
        tex:SetColorTexture(th.accent[1], th.accent[2], th.accent[3], 0.2)
    end)
    return line
end

-- Creates a small inline win-rate bar. Thin wrapper over the shared uikit progress-bar
-- primitive that preserves this file's existing 3-arg call signature and :SetWinRate
-- method name, so every existing call site (row pooling, refresh logic) is unchanged.
local function CreateWinRateBar(parent, width, height)
    local bar = WG.CreateProgressBar(parent, { width = width, height = height, bgAlpha = 0.3, colorMode = "winrate", showLabel = true, labelSize = 8 })
    function bar:SetWinRate(pct, wins, losses)
        bar:SetProgress(pct / 100)
    end
    return bar
end

-- ---------- STATS PANEL UI ----------
local function CreateStatsFrame()
    local mainFrame = WG.mainFrame
    if not mainFrame then return end

    local f = CreateFrame("Frame", "WG_StatsFrame", mainFrame)
    f:SetSize(300, 580)
    f:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 5, 0)
    f:SetFrameStrata("HIGH")
    WG.ApplyModernStyle(f)

    -- Shared chrome (accent stripe + title + close button)
    local chrome = WG.CreateWindowChrome(f, { title = L["MATCH_HISTORY"], titleSize = 13 })
    f.title = chrome.title
    local theme = WG.GetActiveTheme()

    CreateSeparator(f, -30)

    -- ====== WIN RATE BAR (big visual summary) ======
    local winRateBar = WG.CreateProgressBar(f, { width = 270, height = 18, bgAlpha = 0.3, colorMode = "winrate", showLabel = true, labelSize = 10 })
    winRateBar:SetPoint("TOP", 0, -36)
    f.winRateBar = winRateBar
    f.winBarText = winRateBar._label

    -- Overall summary text
    f.summary = f:CreateFontString(nil, "OVERLAY")
    f.summary:SetFont(FONT, 11)
    f.summary:SetPoint("TOPLEFT", 15, -58)
    f.summary:SetPoint("TOPRIGHT", -15, -58)
    f.summary:SetJustifyH("LEFT")

    -- Today's session stats
    f.todayLine = f:CreateFontString(nil, "OVERLAY")
    f.todayLine:SetFont(FONT, 10)
    f.todayLine:SetPoint("TOPLEFT", 15, -72)
    f.todayLine:SetPoint("TOPRIGHT", -15, -72)
    f.todayLine:SetJustifyH("LEFT")

    -- Streak line
    f.streakLine = f:CreateFontString(nil, "OVERLAY")
    f.streakLine:SetFont(FONT, 10)
    f.streakLine:SetPoint("TOPLEFT", 15, -85)
    f.streakLine:SetPoint("TOPRIGHT", -15, -85)
    f.streakLine:SetJustifyH("LEFT")

    CreateSeparator(f, -98)

    -- Tab strip (Opponents / Maps / Log / Session) — real underline active-indicator
    -- instead of the old background-recolor-only buttons.
    local tabStrip = WG.CreateTabStrip(f, {
        {key = "opponents", label = L["TAB_OPPONENTS"]},
        {key = "maps",      label = L["TAB_MAPS"]},
        {key = "log",       label = L["TAB_LOG"]},
        {key = "session",   label = L["TAB_SESSION"]},
    }, {
        spacing = 16,
        onSelect = function(key)
            activeTab = key
            f:RefreshContent()
            PlaySound(856)
        end,
    })
    tabStrip:SetPoint("TOPLEFT", 12, -103)
    f.tabStrip = tabStrip

    CreateSeparator(f, -130)

    -- Scroll area
    local scrollFrame = CreateFrame("ScrollFrame", "WG_StatsScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -135)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 45)
    WG.ApplyModernStyle(scrollFrame)
    WG.StyleScrollBar(scrollFrame)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(250, 1)
    scrollFrame:SetScrollChild(scrollContent)
    f.scrollContent = scrollContent

    f.rows = {}

    CreateSeparator(f, -535)

    -- Advanced button
    local advBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    advBtn:SetSize(80, 22)
    advBtn:SetPoint("BOTTOMRIGHT", -10, 12)
    advBtn:SetText("Advanced")
    WG.StyleButton(advBtn)
    advBtn:SetScript("OnClick", function() if WG.ToggleAdvancedStats then WG.ToggleAdvancedStats() end end)

    -- Clear History button
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 22)
    clearBtn:SetPoint("RIGHT", advBtn, "LEFT", -6, 0)
    clearBtn:SetText(L["CLEAR_HISTORY"])
    WG.StyleButton(clearBtn)

    clearBtn._confirmPending = false
    clearBtn:SetScript("OnClick", function(self)
        if self._confirmPending then
            WG_History.records = {}
            self._confirmPending = false
            self:SetText(L["CLEAR_HISTORY"])
            local fs = self:GetFontString()
            if fs then fs:SetTextColor(unpack(WG.GetActiveTheme().buttonText)) end
            self._hasInlineColor = false
            f:RefreshContent()
            print(AccentColor(L["CHAT_PREFIX"]) .. " " .. L["MSG_HISTORY_CLEARED"])
        else
            self._confirmPending = true
            self._hasInlineColor = true
            self:SetText("|cffff4444" .. L["CONFIRM_CLEAR"] .. "|r")
            C_Timer.After(3, function()
                if self._confirmPending then
                    self._confirmPending = false
                    self:SetText(L["CLEAR_HISTORY"])
                    local fs = self:GetFontString()
                    if fs then fs:SetTextColor(unpack(WG.GetActiveTheme().buttonText)) end
                    self._hasInlineColor = false
                end
            end)
        end
    end)

    -- Record count
    f.countText = f:CreateFontString(nil, "OVERLAY")
    f.countText:SetFont(FONT, 10)
    f.countText:SetPoint("BOTTOMLEFT", 12, 16)
    f.countText:SetTextColor(unpack(theme.footerColor))
    WG.RegisterThemedElement(f.countText, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().footerColor))
    end)

    -- ---------- CONFIRM DELETE POPUP ----------
    local confirmPopup = CreateFrame("Frame", "WG_ConfirmDelete", f, "BackdropTemplate")
    confirmPopup:SetSize(280, 100)
    confirmPopup:SetFrameStrata("DIALOG")
    confirmPopup:SetFrameLevel(100)
    confirmPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    WG.ApplyModernStyle(confirmPopup)
    local bg = WG.GetActiveTheme().backdropBg
    confirmPopup:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    local bdr = WG.GetActiveTheme().backdropBorder
    confirmPopup:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], 1)
    confirmPopup:EnableMouse(true)
    confirmPopup:Hide()

    WG.RegisterThemedElement(confirmPopup, function(popup)
        local t = WG.GetActiveTheme()
        popup:SetBackdropColor(t.backdropBg[1], t.backdropBg[2], t.backdropBg[3], 1)
        popup:SetBackdropBorderColor(t.backdropBorder[1], t.backdropBorder[2], t.backdropBorder[3], 1)
    end)

    CreateAccentStripe(confirmPopup)

    confirmPopup.text = confirmPopup:CreateFontString(nil, "OVERLAY")
    confirmPopup.text:SetFont(FONT, 11, "")
    confirmPopup.text:SetPoint("TOPLEFT", 15, -15)
    confirmPopup.text:SetPoint("TOPRIGHT", -15, -15)
    confirmPopup.text:SetJustifyH("CENTER")
    confirmPopup.text:SetWordWrap(true)
    WG.RegisterThemedElement(confirmPopup.text, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().titleColor))
    end)
    confirmPopup.text:SetTextColor(unpack(WG.GetActiveTheme().titleColor))

    local confirmYes = CreateFrame("Button", nil, confirmPopup, "UIPanelButtonTemplate")
    confirmYes:SetSize(80, 24)
    confirmYes:SetPoint("BOTTOMRIGHT", confirmPopup, "BOTTOM", -5, 12)
    confirmYes:SetText("|cffff4444Delete|r")
    WG.StyleButton(confirmYes)
    confirmYes._hasInlineColor = true

    local confirmNo = CreateFrame("Button", nil, confirmPopup, "UIPanelButtonTemplate")
    confirmNo:SetSize(80, 24)
    confirmNo:SetPoint("BOTTOMLEFT", confirmPopup, "BOTTOM", 5, 12)
    confirmNo:SetText("Cancel")
    WG.StyleButton(confirmNo)

    confirmNo:SetScript("OnClick", function()
        confirmPopup:Hide()
        PlaySound(856)
    end)

    local function ShowDeleteConfirm(message, onConfirm)
        confirmPopup.text:SetText(message)
        confirmYes:SetScript("OnClick", function()
            onConfirm()
            confirmPopup:Hide()
            f:RefreshContent()
            PlaySound(856)
        end)
        confirmPopup:Show()
        PlaySound(856)
    end

    local function RemoveRecordsByOpponent(opponentName)
        local records = GetRecords()
        for i = #records, 1, -1 do
            local key = NormalizeName(records[i].opponent) or records[i].opponent
            if key == opponentName then
                table.remove(records, i)
            end
        end
    end

    local function RemoveRecordsByMap(mapName)
        local records = GetRecords()
        for i = #records, 1, -1 do
            if records[i].map == mapName then
                table.remove(records, i)
            end
        end
    end

    local function RemoveRecordByIndex(index)
        local records = GetRecords()
        if records[index] then
            table.remove(records, index)
        end
    end

    -- ---------- CONTENT RENDERING ----------
    local ROW_HEIGHT = 26

    local function ClearRows()
        for _, row in ipairs(f.rows) do
            row:Hide()
            if row._winBar then row._winBar:Hide() end
            if row._dotTex then row._dotTex:Hide() end
        end
        if f.sessionToggle then f.sessionToggle:Hide(); f.sessionCopy:Hide() end
    end

    local function GetRow(index, yOffset)
        local y = yOffset or -((index - 1) * ROW_HEIGHT)
        if f.rows[index] then
            local row = f.rows[index]
            row:ClearAllPoints()
            row:SetSize(250, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 5, y)
            row:SetScript("OnMouseDown", nil)
            row:SetScript("OnEnter", nil)
            row:SetScript("OnLeave", nil)
            row:EnableMouse(false)
            row._hlTex:SetAlpha(index % 2 == 0 and 1 or 0)
            if row._winBar then row._winBar:Hide() end
            if row._dotTex then row._dotTex:Hide() end
            row:Show()
            return row
        end
        local row = CreateFrame("Frame", nil, scrollContent)
        row:SetSize(250, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 5, y)

        row.text = row:CreateFontString(nil, "OVERLAY")
        row.text:SetFont(FONT, 11)
        row.text:SetPoint("LEFT", 5, 0)
        row.text:SetPoint("RIGHT", -5, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)

        local hlTex = row:CreateTexture(nil, "BACKGROUND")
        hlTex:SetAllPoints()
        hlTex:SetColorTexture(unpack(WG.GetActiveTheme().rowHighlight))
        hlTex:SetAlpha(0)
        row._hlTex = hlTex

        if index % 2 == 0 then
            hlTex:SetAlpha(1)
        end

        WG.RegisterThemedElement(row, function(r)
            r._hlTex:SetColorTexture(unpack(WG.GetActiveTheme().rowHighlight))
        end)

        f.rows[index] = row
        return row
    end

    -- Get or create a small win rate bar attached to a row
    local function GetRowWinBar(row)
        if not row._winBar then
            row._winBar = CreateWinRateBar(row, 50, 12)
        end
        row._winBar:Show()
        return row._winBar
    end

    -- Get or create a colored result dot for a row
    local function GetRowDot(row)
        if not row._dotTex then
            local dot = row:CreateTexture(nil, "OVERLAY")
            dot:SetSize(8, 8)
            row._dotTex = dot
        end
        row._dotTex:Show()
        return row._dotTex
    end

    local function RenderOpponents()
        ClearRows()
        local data = GetOpponentStats()
        scrollContent:SetHeight(math.max(#data * ROW_HEIGHT, 1))
        for i, s in ipairs(data) do
            local row = GetRow(i)

            -- Result dot colored by overall win rate
            local dot = GetRowDot(row)
            dot:ClearAllPoints()
            dot:SetPoint("LEFT", 4, 0)
            if s.pct >= 50 then
                local t = WG.GetActiveTheme()
                local hex = t.inlineGreen
                local r = tonumber(hex:sub(1,2), 16) / 255
                local g = tonumber(hex:sub(3,4), 16) / 255
                local b = tonumber(hex:sub(5,6), 16) / 255
                dot:SetColorTexture(r, g, b, 1)
            else
                local t = WG.GetActiveTheme()
                local hex = t.inlineLoss or "ff4444"
                local r = tonumber(hex:sub(1,2), 16) / 255
                local g = tonumber(hex:sub(3,4), 16) / 255
                local b = tonumber(hex:sub(5,6), 16) / 255
                dot:SetColorTexture(r, g, b, 1)
            end

            -- Name + W/L text (shifted right for dot)
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", dot, "RIGHT", 4, 0)
            row.text:SetPoint("RIGHT", -60, 0)
            row.text:SetText(CharColor(s.name) .. "  " .. WinColor(s.wins .. L["WIN_SHORT"]) .. "/" .. LossColor(s.losses .. L["LOSS_SHORT"]))

            -- Inline win rate bar
            local bar = GetRowWinBar(row)
            bar:ClearAllPoints()
            bar:SetPoint("RIGHT", -2, 0)
            bar:SetWinRate(s.pct, s.wins, s.losses)

            row:EnableMouse(true)

            row:SetScript("OnMouseDown", function(_, button)
                if button == "RightButton" then
                    ShowDeleteConfirm(
                        "Delete all records vs " .. s.name .. "?\n(" .. s.total .. " matches)",
                        function() RemoveRecordsByOpponent(s.name) end
                    )
                else
                    ShowProfileCard(s.name, f)
                end
            end)
            row:SetScript("OnEnter", function(self)
                self._hlTex:SetColorTexture(unpack(WG.GetActiveTheme().selectionFaint))
                self._hlTex:SetAlpha(1)
            end)
            row:SetScript("OnLeave", function(self)
                self._hlTex:SetColorTexture(unpack(WG.GetActiveTheme().rowHighlight))
                self._hlTex:SetAlpha(i % 2 == 0 and 1 or 0)
            end)
        end
        if #data == 0 then
            local row = GetRow(1)
            row.text:SetText(DrawColor(L["NO_MATCH_DATA"]))
        end
    end

    local function RenderMaps()
        ClearRows()
        local data = GetMapStats()
        scrollContent:SetHeight(math.max(#data * ROW_HEIGHT, 1))
        for i, s in ipairs(data) do
            local row = GetRow(i)

            -- Name + W/L + played count
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", 5, 0)
            row.text:SetPoint("RIGHT", -60, 0)
            row.text:SetText(AccentColor(s.name) .. "  " .. WinColor(s.wins .. L["WIN_SHORT"]) .. "/" .. LossColor(s.losses .. L["LOSS_SHORT"]) .. "  " .. DrawColor("(" .. s.total .. ")"))

            -- Inline win rate bar
            local bar = GetRowWinBar(row)
            bar:ClearAllPoints()
            bar:SetPoint("RIGHT", -2, 0)
            bar:SetWinRate(s.pct, s.wins, s.losses)

            row:EnableMouse(true)

            row:SetScript("OnMouseDown", function(_, button)
                if button == "RightButton" then
                    ShowDeleteConfirm(
                        "Delete all records on " .. s.name .. "?\n(" .. s.total .. " matches)",
                        function() RemoveRecordsByMap(s.name) end
                    )
                end
            end)
            row:SetScript("OnEnter", function(self)
                self._hlTex:SetColorTexture(unpack(WG.GetActiveTheme().selectionFaint))
                self._hlTex:SetAlpha(1)
            end)
            row:SetScript("OnLeave", function(self)
                self._hlTex:SetColorTexture(unpack(WG.GetActiveTheme().rowHighlight))
                self._hlTex:SetAlpha(i % 2 == 0 and 1 or 0)
            end)
        end
        if #data == 0 then
            local row = GetRow(1)
            row.text:SetText(DrawColor(L["NO_MATCH_DATA"]))
        end
    end

    -- Floating detail popup for log entry hover
    local detailPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    detailPanel:SetFrameStrata("TOOLTIP")
    detailPanel:SetSize(250, 1)
    WG.ApplyModernStyle(detailPanel)
    local dpBg = WG.GetActiveTheme().backdropBg
    detailPanel:SetBackdropColor(dpBg[1], dpBg[2], dpBg[3], 1)
    local dpBdr = WG.GetActiveTheme().backdropBorder
    detailPanel:SetBackdropBorderColor(dpBdr[1], dpBdr[2], dpBdr[3], 1)
    detailPanel:EnableMouse(false)
    detailPanel:Hide()
    detailPanel.lines = {}
    detailPanel._pinned = false
    detailPanel._pinnedRec = nil

    WG.RegisterThemedElement(detailPanel, function(panel)
        local th = WG.GetActiveTheme()
        panel:SetBackdropColor(th.backdropBg[1], th.backdropBg[2], th.backdropBg[3], 1)
        panel:SetBackdropBorderColor(th.backdropBorder[1], th.backdropBorder[2], th.backdropBorder[3], 1)
    end)

    -- Accent stripe on detail panel
    CreateAccentStripe(detailPanel)

    local function ClearDetailLines()
        for _, line in ipairs(detailPanel.lines) do
            line:Hide()
        end
    end

    local function GetDetailLine(index)
        if detailPanel.lines[index] then
            detailPanel.lines[index]:Show()
            detailPanel.lines[index]:SetWordWrap(false)
            return detailPanel.lines[index]
        end
        local fs = detailPanel:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT, 11, "")
        fs:SetPoint("TOPLEFT", 10, -10 - ((index - 1) * 18))
        fs:SetPoint("RIGHT", -10, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)
        fs:SetAlpha(1)
        detailPanel.lines[index] = fs
        return fs
    end

    local LINE_H = 18
    local SECTION_PAD = 8

    local function BuildDetailContent(rec)
        ClearDetailLines()
        local hasPlayers = rec.players and #rec.players > 0
        local veto = GetVetoForRecord(rec)
        local hasNote = rec.note and rec.note ~= ""
        if not hasPlayers and not veto and not hasNote then return 0 end

        local t = WG.GetActiveTheme()
        local lineIdx = 0
        local isShuffle = rec.matchType == "Solo Shuffle"

        -- ====== MATCH HEADER ======
        local resultStr
        if rec.result == "win" then resultStr = WinColor("VICTORY")
        elseif rec.result == "loss" then resultStr = LossColor("DEFEAT")
        else resultStr = DrawColor("DRAW") end

        lineIdx = lineIdx + 1
        GetDetailLine(lineIdx):SetText(resultStr .. "  " .. AccentColor(rec.matchType or "Unknown") .. "  " .. CharColor(rec.map))

        local duration = rec.duration and rec.duration > 0 and string.format("%d:%02d", math.floor(rec.duration / 60), rec.duration % 60) or nil
        if duration then
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(AccentColor(duration) .. " match  " .. "|cff888888" .. TimeAgo(rec.timestamp) .. "|r")
        else
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText("|cff888888" .. TimeAgo(rec.timestamp) .. "|r")
        end

      if hasPlayers then
        -- Find self
        local selfStats
        for _, p in ipairs(rec.players) do
            if p.name and rec.playerName and p.name == rec.playerName then
                selfStats = p
                break
            end
        end

        -- ====== YOUR PERFORMANCE ======
        if selfStats then
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(" ")

            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(AccentColor("-- " .. L["YOUR_PERFORMANCE"] .. " --") .. "  " .. ClassColoredName(selfStats.name, selfStats.classToken))

            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(
                "  |cffcccccc" .. L["STAT_DMG"] .. ":|r " .. AccentColor(FormatNumber(selfStats.damage)) ..
                "    |cffcccccc" .. L["STAT_HEAL"] .. ":|r " .. WinColor(FormatNumber(selfStats.healing)) ..
                "    |cffcccccc" .. L["STAT_KB"] .. ":|r " .. CharColor(tostring(selfStats.kills)) ..
                "    |cffcccccc" .. L["STAT_DEATHS"] .. ":|r " .. LossColor(tostring(selfStats.deaths))
            )

            if isShuffle and selfStats.roundsWon then
                lineIdx = lineIdx + 1
                GetDetailLine(lineIdx):SetText("  |cffcccccc" .. L["STAT_ROUNDS_WON"] .. ":|r " .. AccentColor(tostring(selfStats.roundsWon)))
            end
        end

        -- ====== TEAM SORTING ======
        local winners, losers = {}, {}
        if rec.result == "win" then
            for _, p in ipairs(rec.players) do
                if selfStats and p.faction == selfStats.faction then
                    table.insert(winners, p)
                else
                    table.insert(losers, p)
                end
            end
        elseif rec.result == "loss" then
            for _, p in ipairs(rec.players) do
                if selfStats and p.faction == selfStats.faction then
                    table.insert(losers, p)
                else
                    table.insert(winners, p)
                end
            end
        else
            for _, p in ipairs(rec.players) do
                table.insert(winners, p)
            end
        end

        -- Column header for scoreboard
        local colHeader = "  |cffbbbbbb" .. L["STAT_DMG"] .. "      " .. L["STAT_HEAL"] .. "     " .. L["STAT_KB"] .. "  " .. L["STAT_DEATHS"] .. "|r"
        if isShuffle then colHeader = colHeader .. " |cffbbbbbb" .. L["STAT_ROUNDS_SHORT"] .. "|r" end

        local function PlayerLine(p)
            local line = "  " .. ClassColoredName(p.name or "???", p.classToken)
            line = line .. "  " .. AccentColor(FormatNumber(p.damage))
            line = line .. "  " .. WinColor(FormatNumber(p.healing))
            line = line .. "  " .. CharColor(tostring(p.kills))
            line = line .. "  " .. LossColor(tostring(p.deaths))
            if isShuffle and p.roundsWon then
                line = line .. "  " .. AccentColor(tostring(p.roundsWon))
            end
            return line
        end

        -- ====== WINNERS ======
        if #winners > 0 and rec.result ~= "draw" then
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(" ")

            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(WinColor(">> " .. L["WINNERS"] .. " <<"))

            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(colHeader)

            for _, p in ipairs(winners) do
                lineIdx = lineIdx + 1
                GetDetailLine(lineIdx):SetText(PlayerLine(p))
            end
        end

        -- ====== LOSERS ======
        if #losers > 0 and rec.result ~= "draw" then
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(" ")

            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(LossColor(">> " .. L["LOSERS"] .. " <<"))

            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(colHeader)

            for _, p in ipairs(losers) do
                lineIdx = lineIdx + 1
                GetDetailLine(lineIdx):SetText(PlayerLine(p))
            end
        end

        -- ====== DRAW ======
        if rec.result == "draw" and #winners > 0 then
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(" ")

            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(DrawColor(">> " .. L["PLAYERS"] .. " <<"))

            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(colHeader)

            for _, p in ipairs(winners) do
                lineIdx = lineIdx + 1
                GetDetailLine(lineIdx):SetText(PlayerLine(p))
            end
        end
      end  -- if hasPlayers

        -- ====== MAP VETO ======
        if veto and veto.banLog and #veto.banLog > 0 then
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(" ")
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(AccentColor("-- " .. L["VETO_RECAP_HEADER"] ..
                (veto.format and (" (" .. veto.format .. ")") or "") .. " --"))
            local seq = {}
            for _, b in ipairs(veto.banLog) do
                local icon = (b.action == "pick") and WinColor("\226\156\147") or LossColor("\226\156\149")  -- ✓ / ✕
                seq[#seq + 1] = icon .. " " .. b.map
            end
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText("  " .. table.concat(seq, "   "))
            if veto.maps and #veto.maps > 0 then
                lineIdx = lineIdx + 1
                GetDetailLine(lineIdx):SetText("  |cffcccccc" .. L["TAB_MAPS"] .. ":|r " .. CharColor(table.concat(veto.maps, ", ")))
            end
        end

        -- ====== NOTE ======
        if hasNote then
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(" ")
            lineIdx = lineIdx + 1
            GetDetailLine(lineIdx):SetText(AccentColor("-- " .. L["NOTE_HEADER"] .. " --"))
            local noteLine = GetDetailLine(lineIdx + 1)
            noteLine:SetWordWrap(true)
            noteLine:SetText("  |cffdddddd" .. rec.note .. "|r")
            lineIdx = lineIdx + 1 + math.max(1, math.ceil(noteLine:GetStringHeight() / LINE_H))
        end

        return lineIdx * LINE_H + 16 + SECTION_PAD
    end

    -- Right-click menu on a log row: note / delete / view veto.
    local function ShowRecordMenu(owner, rec, index)
        MenuUtil.CreateContextMenu(owner, function(_, root)
            root:CreateTitle(CharColor(rec.opponent) .. "  " .. rec.map)

            root:CreateButton(rec.note and rec.note ~= "" and L["NOTE_EDIT"] or L["NOTE_ADD"], function()
                if not noteEditor then
                    noteEditor = WG.CreateTextPopup({
                        title = L["NOTE_TITLE"], multiline = true, width = 380, height = 150,
                        onSave = function(text)
                            if noteEditor._rec then
                                noteEditor._rec.note = (text ~= "" and text) or nil
                                if statsFrame then statsFrame:RefreshContent() end
                            end
                        end,
                    })
                end
                noteEditor._rec = rec
                noteEditor:Open(rec.note or "")
            end)

            if GetVetoForRecord(rec) then
                root:CreateButton(L["VIEW_VETO"], function()
                    if owner._showDetail then owner._showDetail(true) end
                end)
            end

            root:CreateDivider()
            root:CreateButton("|cffff4444" .. L["MATCH_DELETE"] .. "|r", function()
                local resStr = rec.result == "win" and L["WIN"] or rec.result == "loss" and L["LOSS"] or L["DRAW"]
                ShowDeleteConfirm(
                    "Delete this match?\n" .. resStr .. " vs " .. rec.opponent .. " on " .. rec.map,
                    function() RemoveRecordByIndex(index) end
                )
            end)
        end)
    end

    local function RenderLog()
        ClearRows()
        detailPanel._pinned = false
        detailPanel._pinnedRec = nil
        detailPanel:Hide()
        local records = GetRecords()
        if #records == 0 then
            scrollContent:SetHeight(ROW_HEIGHT)
            local row = GetRow(1)
            row.text:SetText(DrawColor(L["NO_MATCH_DATA"]))
            return
        end

        scrollContent:SetHeight(math.max(#records * ROW_HEIGHT, 1))

        for i, rec in ipairs(records) do
            local row = GetRow(i)

            -- Colored result dot
            local dot = GetRowDot(row)
            dot:ClearAllPoints()
            dot:SetPoint("LEFT", 4, 0)
            if rec.result == "win" then
                local t = WG.GetActiveTheme()
                local hex = t.inlineGreen
                dot:SetColorTexture(tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255, 1)
            elseif rec.result == "loss" then
                local t = WG.GetActiveTheme()
                local hex = t.inlineLoss or "ff4444"
                dot:SetColorTexture(tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255, 1)
            else
                dot:SetColorTexture(0.6, 0.6, 0.6, 1)
            end

            local resultStr
            if rec.result == "win" then resultStr = WinColor(L["WIN_SHORT"])
            elseif rec.result == "loss" then resultStr = LossColor(L["LOSS_SHORT"])
            else resultStr = DrawColor(L["DRAW_SHORT"]) end

            local ago = TimeAgo(rec.timestamp)
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", dot, "RIGHT", 4, 0)
            row.text:SetPoint("RIGHT", -5, 0)
            local debugTag = rec.debug and DrawColor("[DBG] ") or ""
            local noteTag = rec.note and rec.note ~= "" and AccentColor("\226\151\143 ") or ""  -- ● marker
            row.text:SetText(debugTag .. noteTag .. resultStr .. " vs " .. CharColor(rec.opponent) .. "  " .. rec.map .. "  " .. DrawColor(ago))

            local hasDetail = (rec.players and #rec.players > 0) or (rec.note and rec.note ~= "") or (GetVetoForRecord(rec) ~= nil)

            local function ShowDetail(pin)
                detailPanel:SetWidth(500)
                local panelHeight = BuildDetailContent(rec)
                if panelHeight <= 0 then detailPanel:Hide(); return end
                local maxW = 0
                for _, line in ipairs(detailPanel.lines) do
                    if line:IsShown() then
                        local tw = line:GetStringWidth()
                        if tw > maxW then maxW = tw end
                    end
                end
                detailPanel:ClearAllPoints()
                detailPanel:SetPoint("TOPLEFT", f, "TOPRIGHT", 5, -95)
                detailPanel:SetSize(math.max(320, maxW + 20), panelHeight)
                detailPanel:Show()
                if pin then detailPanel._pinned = true; detailPanel._pinnedRec = rec end
            end
            row._showDetail = ShowDetail

            row:EnableMouse(true)
            row._rec = rec
            row:SetScript("OnEnter", function(self)
                self._hlTex:SetColorTexture(unpack(WG.GetActiveTheme().selectionFaint))
                self._hlTex:SetAlpha(1)
                if hasDetail and not detailPanel._pinned then ShowDetail(false) end
            end)
            row:SetScript("OnLeave", function(self)
                self._hlTex:SetColorTexture(unpack(WG.GetActiveTheme().rowHighlight))
                self._hlTex:SetAlpha(i % 2 == 0 and 1 or 0)
                if not detailPanel._pinned then detailPanel:Hide() end
            end)
            row:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" then
                    ShowRecordMenu(self, rec, i)
                    return
                end
                if hasDetail and detailPanel._pinned and detailPanel._pinnedRec == rec then
                    detailPanel._pinned = false
                    detailPanel._pinnedRec = nil
                    detailPanel:Hide()
                elseif hasDetail then
                    ShowDetail(true)
                end
            end)
        end
    end

    -- WL string like "8-4" (draws appended only if any)
    local function WLString(e, colored)
        local s = (colored and WinColor(e.w) or tostring(e.w)) .. "-" .. (colored and LossColor(e.l) or tostring(e.l))
        if e.d > 0 then s = s .. "-" .. (colored and DrawColor(e.d) or tostring(e.d)) end
        return s
    end

    -- Plain-text block for the copy popup (no color escapes).
    local function BuildRecapText(sum)
        local span = (sum.startTime and sum.endTime) and FormatSpan(sum.endTime - sum.startTime) or "0m"
        local lines = {
            "Wargames session - " .. span,
            string.format("Record: %d-%d%s (%d%%)", sum.w, sum.l, sum.d > 0 and ("-" .. sum.d) or "", sum.pct),
        }
        if #sum.modeOrder > 0 then
            local parts = {}
            for _, k in ipairs(sum.modeOrder) do parts[#parts + 1] = k .. " " .. WLString(sum.byMode[k]) end
            lines[#lines + 1] = "By mode: " .. table.concat(parts, ", ")
        end
        if #sum.mapOrder > 0 then
            local parts = {}
            for i, k in ipairs(sum.mapOrder) do
                if i > 6 then break end
                parts[#parts + 1] = k .. " " .. WLString(sum.byMap[k])
            end
            lines[#lines + 1] = "By map: " .. table.concat(parts, ", ")
        end
        if sum.topOpp then
            lines[#lines + 1] = "Top opponent: " .. sum.topOpp .. " " .. WLString(sum.byOpp[sum.topOpp])
        end
        return table.concat(lines, "\n")
    end

    -- Session tab: live summary + Start/End-session toggle + Copy-for-Discord.
    local function RenderSession()
        ClearRows()
        detailPanel._pinned = false; detailPanel:Hide()

        -- persistent controls (built once, parented to the scroll child)
        if not f.sessionToggle then
            f.sessionToggle = CreateFrame("Button", nil, scrollContent, "UIPanelButtonTemplate")
            f.sessionToggle:SetSize(120, 20)
            f.sessionToggle:GetFontString():SetFont(FONT, 10)
            WG.StyleButton(f.sessionToggle)
            f.sessionToggle:SetScript("OnClick", function()
                local ov = WG_History.sessionOverride
                if ov.active then
                    ov.active = false
                else
                    ov.active = true; ov.startTime = time()
                end
                f:RefreshContent()
                PlaySound(856)
            end)

            f.sessionCopy = CreateFrame("Button", nil, scrollContent, "UIPanelButtonTemplate")
            f.sessionCopy:SetSize(130, 20)
            f.sessionCopy:GetFontString():SetFont(FONT, 10)
            f.sessionCopy:SetText(L["SESSION_COPY"])
            WG.StyleButton(f.sessionCopy)
            f.sessionCopy:SetScript("OnClick", function()
                if not recapPopup then
                    recapPopup = WG.CreateTextPopup({ title = L["SESSION_TITLE"], multiline = true, readOnly = true, width = 440, height = 220 })
                end
                recapPopup:Open(BuildRecapText(GetSessionSummary()))
                PlaySound(856)
            end)
        end

        local ov = WG_History.sessionOverride
        f.sessionToggle:SetText(ov.active and L["SESSION_END"] or L["SESSION_START"])

        local sum = GetSessionSummary()
        local yi = 0
        local function line(text)
            yi = yi + 1
            GetRow(yi).text:SetText(text)
        end
        local function kv(k, v) line(AccentColor(k .. "  ") .. v) end

        if sum.total == 0 then
            line(DrawColor(L["SESSION_NO_MATCHES"]))
        else
            local span = (sum.startTime and sum.endTime) and FormatSpan(sum.endTime - sum.startTime) or "0m"
            local pctStr = sum.pct >= 50 and WinColor(sum.pct .. "%") or LossColor(sum.pct .. "%")
            kv(L["SESSION_RECORD"], WLString(sum, true) .. "  " .. pctStr)
            kv(L["SESSION_LENGTH"], span)
            if #sum.modeOrder > 0 then
                local parts = {}
                for _, k in ipairs(sum.modeOrder) do parts[#parts + 1] = k .. " " .. WLString(sum.byMode[k], true) end
                kv(L["SESSION_BY_MODE"], table.concat(parts, "  \194\183  "))
            end
            for i, k in ipairs(sum.mapOrder) do
                if i > 6 then break end
                if i == 1 then kv(L["SESSION_BY_MAP"], k .. " " .. WLString(sum.byMap[k], true))
                else line("            " .. CharColor(k) .. " " .. WLString(sum.byMap[k], true)) end
            end
            if sum.topOpp then
                kv(L["SESSION_TOP_OPP"], CharColor(sum.topOpp) .. " " .. WLString(sum.byOpp[sum.topOpp], true))
            end
        end

        line(DrawColor(ov.active and L["SESSION_MANUAL_HINT"] or L["SESSION_AUTO_HINT"]))

        -- place the two buttons below the text rows
        yi = yi + 1
        f.sessionToggle:ClearAllPoints()
        f.sessionToggle:SetPoint("TOPLEFT", 5, -((yi - 1) * ROW_HEIGHT) - 4)
        f.sessionCopy:ClearAllPoints()
        f.sessionCopy:SetPoint("LEFT", f.sessionToggle, "RIGHT", 8, 0)
        f.sessionToggle:Show(); f.sessionCopy:Show()

        scrollContent:SetHeight(yi * ROW_HEIGHT + 12)
    end

    local function ResizePanel()
        local maxWidth = 0
        for _, row in ipairs(f.rows) do
            if row:IsShown() then
                local tw = row.text:GetStringWidth()
                if tw > maxWidth then maxWidth = tw end
            end
        end
        -- Account for win rate bars in opponent/map tabs
        local extraWidth = (activeTab == "opponents" or activeTab == "maps") and 60 or 0
        local neededWidth = math.max(MIN_PANEL_WIDTH, math.min(maxWidth + WIDTH_PADDING + extraWidth, MAX_PANEL_WIDTH))
        f:SetWidth(neededWidth)
        local contentWidth = neededWidth - 50
        scrollContent:SetWidth(contentWidth)
        for _, row in ipairs(f.rows) do
            if row:IsShown() then
                row:SetWidth(contentWidth)
            end
        end
        -- Resize win rate bar
        f.winRateBar:SetWidth(neededWidth - 30)
    end

    function f:RefreshContent()
        confirmPopup:Hide()
        -- Update big win rate bar
        local w, l, d, total, pct = GetOverallStats()
        if total > 0 then
            f.winRateBar:SetProgress(pct / 100, WinColor(w .. L["WIN_SHORT"]) .. " / " .. LossColor(l .. L["LOSS_SHORT"]) .. " / " .. DrawColor(d .. L["DRAW_SHORT"]) .. "  " .. pct .. "% " .. L["WIN_RATE"])
        else
            f.winRateBar:SetProgress(0, DrawColor(L["NO_MATCHES_RECORDED"]))
        end

        -- Summary text
        if total > 0 then
            local pctStr = pct >= 50 and WinColor(pct .. "%") or LossColor(pct .. "%")
            f.summary:SetText(total .. " " .. L["MATCH_HISTORY"]:lower() .. "  " .. pctStr .. " " .. L["WIN_RATE"])
        else
            f.summary:SetText("")
        end

        -- Today's session
        local tw, tl, td, tTotal = GetTodayStats()
        if tTotal > 0 then
            local todayStr = "Today: " .. WinColor(tw .. L["WIN_SHORT"]) .. " / " .. LossColor(tl .. L["LOSS_SHORT"])
            if td > 0 then todayStr = todayStr .. " / " .. DrawColor(td .. L["DRAW_SHORT"]) end
            f.todayLine:SetText(todayStr)
        else
            f.todayLine:SetText("")
        end

        -- Streak line
        local curType, curLen, bestType, bestLen = GetStreakInfo()
        if curType and curLen > 0 then
            local curColor = (curType == "win") and WinColor or (curType == "loss") and LossColor or DrawColor
            local curLabel = curLen .. (curType == "win" and L["WIN_SHORT"] or curType == "loss" and L["LOSS_SHORT"] or L["DRAW_SHORT"])
            local bestColor = (bestType == "win") and WinColor or (bestType == "loss") and LossColor or DrawColor
            local bestLabel = bestLen .. (bestType == "win" and L["WIN_SHORT"] or bestType == "loss" and L["LOSS_SHORT"] or L["DRAW_SHORT"])
            f.streakLine:SetText(L["STREAK"] .. " " .. curColor(curLabel) .. "  |  " .. L["BEST"] .. " " .. bestColor(bestLabel))
        else
            f.streakLine:SetText("")
        end

        -- Update tab highlight
        f.tabStrip:SetActiveTab(activeTab)

        -- Update count
        f.countText:SetText(string.format(L["RECORDS_COUNT"], #GetRecords(), MAX_RECORDS))

        -- Render active tab
        if activeTab == "opponents" then RenderOpponents()
        elseif activeTab == "maps" then RenderMaps()
        elseif activeTab == "session" then RenderSession()
        else RenderLog() end

        ResizePanel()
    end

    -- Profile card is a dependent of the stats window; don't leave it orphaned.
    f:HookScript("OnHide", function()
        if profileCard and profileCard:IsShown() then profileCard:Hide() end
    end)

    f:Hide()
    statsFrame = f
    return f
end

-- ---------- PROFILE CARD ----------
local function CreateProfileCard()
    if profileCard then return profileCard end

    local f = CreateFrame("Frame", "WG_ProfileCard", UIParent)
    f:SetSize(280, 380)
    f:SetFrameStrata("TOOLTIP")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    WG.ApplyModernStyle(f)
    if WG.ApplyUIScale then WG.ApplyUIScale(f) end

    -- Shared chrome (accent stripe + close button); the title FontString doubles as the
    -- dynamic opponent-name header, matching veto.lua's identical repurposing pattern.
    local chrome = WG.CreateWindowChrome(f, { title = "" })
    local theme = WG.GetActiveTheme()

    f.nameText = chrome.title
    f.nameText:SetPoint("RIGHT", chrome.close, "LEFT", -5, 0)
    f.nameText:SetJustifyH("LEFT")

    -- Win rate bar for profile
    local profBar = WG.CreateProgressBar(f, { width = 256, height = 14, bgAlpha = 0.3, colorMode = "winrate", showLabel = true, labelSize = 9 })
    profBar:SetPoint("TOPLEFT", 12, -32)
    f.profBar = profBar
    f.profBarText = profBar._label

    -- Summary line
    f.summaryText = f:CreateFontString(nil, "OVERLAY")
    f.summaryText:SetFont(FONT, 11)
    f.summaryText:SetPoint("TOPLEFT", 12, -50)
    f.summaryText:SetPoint("RIGHT", -12, 0)
    f.summaryText:SetJustifyH("LEFT")

    -- Streak line
    f.streakText = f:CreateFontString(nil, "OVERLAY")
    f.streakText:SetFont(FONT, 10)
    f.streakText:SetPoint("TOPLEFT", 12, -64)
    f.streakText:SetPoint("RIGHT", -12, 0)
    f.streakText:SetJustifyH("LEFT")

    -- Separator
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 8, -78)
    sep:SetPoint("RIGHT", -8, 0)
    sep:SetColorTexture(unpack(theme.backdropBorder))
    WG.RegisterThemedElement(sep, function(t)
        t:SetColorTexture(unpack(WG.GetActiveTheme().backdropBorder))
    end)

    -- Match history sub-header
    local histLabel = f:CreateFontString(nil, "OVERLAY")
    histLabel:SetFont(FONT, 10, "OUTLINE")
    histLabel:SetPoint("TOPLEFT", 12, -86)
    histLabel:SetText(L["MATCH_HISTORY"])
    histLabel:SetTextColor(unpack(theme.headerColor))
    WG.RegisterThemedElement(histLabel, function(fs)
        fs:SetTextColor(unpack(WG.GetActiveTheme().headerColor))
    end)

    -- Scrollable match list
    local scrollFrame = CreateFrame("ScrollFrame", "WG_ProfileScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -100)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)
    WG.ApplyModernStyle(scrollFrame)
    WG.StyleScrollBar(scrollFrame)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(230, 1)
    scrollFrame:SetScrollChild(scrollContent)
    f.scrollContent = scrollContent
    f.matchRows = {}

    -- Empty state
    f.emptyText = f:CreateFontString(nil, "OVERLAY")
    f.emptyText:SetFont(FONT, 11)
    f.emptyText:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
    f.emptyText:SetText(DrawColor(L["NO_MATCHES_VS_OPPONENT"]))
    f.emptyText:Hide()

    f:Hide()
    profileCard = f
    return f
end

ShowProfileCard = function(opponentName, anchorFrame)
    if not opponentName then return end
    local card = CreateProfileCard()
    local profile = GetOpponentProfile(opponentName)
    local t = WG.GetActiveTheme()

    -- Header
    card.nameText:SetText("|cff" .. t.inlineAccent .. opponentName .. "|r")

    if not profile then
        card.summaryText:SetText("")
        card.streakText:SetText("")
        card.emptyText:Show()
        card.profBar:SetProgress(0, "")
        card.profBar:Hide()
        for _, row in ipairs(card.matchRows) do row:Hide() end
        card.scrollContent:SetHeight(1)
    else
        card.emptyText:Hide()
        card.profBar:Show()

        -- Win rate bar
        card.profBar:SetProgress(profile.pct / 100, profile.pct .. "% " .. L["WIN_RATE"])

        -- Summary
        local pctStr = profile.pct >= 50 and WinColor(profile.pct .. "%") or LossColor(profile.pct .. "%")
        card.summaryText:SetText(
            WinColor(profile.wins .. L["WIN_SHORT"]) .. " / " ..
            LossColor(profile.losses .. L["LOSS_SHORT"]) .. " / " ..
            DrawColor(profile.draws .. L["DRAW_SHORT"]) .. "  " ..
            pctStr .. " " .. L["WIN_RATE"]
        )

        -- Streak
        if profile.streak and profile.streak > 0 then
            local sLabel = profile.streak .. (profile.streakType == "win" and L["WIN_SHORT"] or profile.streakType == "loss" and L["LOSS_SHORT"] or L["DRAW_SHORT"])
            local sColor = (profile.streakType == "win") and WinColor or (profile.streakType == "loss") and LossColor or DrawColor
            card.streakText:SetText(L["CURRENT_STREAK"] .. " " .. sColor(sLabel))
        else
            card.streakText:SetText("")
        end

        -- Match list
        local ROW_H = 22
        for _, row in ipairs(card.matchRows) do row:Hide() end

        for i, rec in ipairs(profile.matches) do
            local row = card.matchRows[i]
            if not row then
                row = CreateFrame("Frame", nil, card.scrollContent)
                row:SetHeight(ROW_H)

                -- Result dot
                local dot = row:CreateTexture(nil, "OVERLAY")
                dot:SetSize(8, 8)
                dot:SetPoint("LEFT", 4, 0)
                row._dot = dot

                row.text = row:CreateFontString(nil, "OVERLAY")
                row.text:SetFont(FONT, 10)
                row.text:SetPoint("LEFT", dot, "RIGHT", 4, 0)
                row.text:SetPoint("RIGHT", -5, 0)
                row.text:SetJustifyH("LEFT")
                row.text:SetWordWrap(false)

                local hlTex = row:CreateTexture(nil, "BACKGROUND")
                hlTex:SetAllPoints()
                hlTex:SetColorTexture(unpack(t.rowHighlight))
                hlTex:SetAlpha(i % 2 == 0 and 1 or 0)
                row._hlTex = hlTex
                WG.RegisterThemedElement(row, function(r)
                    r._hlTex:SetColorTexture(unpack(WG.GetActiveTheme().rowHighlight))
                end)

                card.matchRows[i] = row
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -((i-1) * ROW_H))
            row:SetPoint("RIGHT", card.scrollContent, "RIGHT", 0, 0)
            row._hlTex:SetAlpha(i % 2 == 0 and 1 or 0)

            -- Color the dot
            if rec.result == "win" then
                local hex = t.inlineGreen
                row._dot:SetColorTexture(tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255, 1)
            elseif rec.result == "loss" then
                local hex = t.inlineLoss or "ff4444"
                row._dot:SetColorTexture(tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255, 1)
            else
                row._dot:SetColorTexture(0.6, 0.6, 0.6, 1)
            end

            local mType = rec.matchType and ("[" .. rec.matchType .. "]") or ""
            local ago = TimeAgo(rec.timestamp)
            row.text:SetText((rec.map or "?") .. "  " .. DrawColor(mType) .. "  " .. DrawColor(ago))
            row:Show()
        end

        card.scrollContent:SetHeight(math.max(#profile.matches * ROW_H, 1))
    end

    -- Position
    card:ClearAllPoints()
    if anchorFrame then
        if statsFrame and statsFrame:IsShown() then
            card:SetPoint("TOPLEFT", statsFrame, "TOPRIGHT", 5, 0)
        else
            card:SetPoint("LEFT", anchorFrame, "RIGHT", 10, 0)
        end
    else
        card:SetPoint("CENTER")
    end
    card:Show()
end

WG.ShowProfileCard = ShowProfileCard
WG.GetMapStats = GetMapStats
WG.GetOpponentStats = GetOpponentStats
WG.FormatNumber = FormatNumber
function WG.HideProfileCard()
    if profileCard and profileCard:IsShown() then
        profileCard:Hide()
    end
end

-- ---------- THEME CHANGE CALLBACK ----------
WG.OnThemeChanged = function()
    if statsFrame and statsFrame:IsShown() then
        statsFrame:RefreshContent()
    end
    if profileCard and profileCard:IsShown() then
        profileCard:Hide()
    end
end

-- ---------- PUBLIC API ----------
function WG.ToggleStatsFrame()
    if not WG.mainFrame then return end
    if not statsFrame then
        CreateStatsFrame()
    end
    if not statsFrame then return end

    if statsFrame:IsShown() then
        statsFrame:Hide()
    else
        if WG.CloseSecondaryWindows then WG.CloseSecondaryWindows("WG_StatsFrame") end
        statsFrame:Show()
        statsFrame:RefreshContent()
    end
end

function WG.HideStatsFrame()
    if statsFrame and statsFrame:IsShown() then
        statsFrame:Hide()
    end
    if profileCard and profileCard:IsShown() then
        profileCard:Hide()
    end
end

-- Debug: /war debugmatch <opponent> [win|loss]
-- Fakes a challenge + records a match result for testing nemesis/rival messages
function WG.DebugMatch(args)
    local opponent, result = args:match("^(%S+)%s*(%S*)")
    if not opponent or opponent == "" then
        print(AccentColor(L["CHAT_PREFIX"]) .. " Usage: /war debugmatch <name> [win|loss]")
        return
    end
    result = (result ~= "" and result) or "win"
    if result ~= "win" and result ~= "loss" and result ~= "draw" then
        print(AccentColor(L["CHAT_PREFIX"]) .. " Result must be win, loss, or draw.")
        return
    end
    -- Fake a challenge so RecordMatch doesn't bail
    WG.lastChallenge = {
        opponent  = opponent,
        map       = "Debug Arena",
        matchSize = "ARENA_2V2",
        timestamp = time() - 120,
        debug     = true,
    }
    RecordMatch(result, {}, UnitName("player"))
end
