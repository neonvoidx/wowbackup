-- advanced.lua: WarGames+ Advanced Stats Panel

local WG = _G["WargamesPlus"]
if not WG then return end
local L = WG.L or setmetatable({}, { __index = function(_, k) return tostring(k) end })

local FONT = WG.ADDON_FONT
local FRAME_W, FRAME_H = 900, 620
local CONTENT_W = 840
local PAD = 12 -- consistent left/right padding inside scroll content
local SECTION_GAP = 30
local BAR_HEIGHT = 18
local CARD_W, CARD_H = 180, 80

-- ---------- HELPERS ----------
local function HexToRGB(hex)
    if not hex or #hex < 6 then return 1, 1, 1 end
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    return r, g, b
end

local function FormatDuration(seconds)
    if not seconds or seconds <= 0 then return "0:00" end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end

local FormatNumber = WG.FormatNumber or function(n)
    if not n then return "0" end
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if n >= 1000 then return string.format("%.1fK", n / 1000) end
    return tostring(math.floor(n))
end

local function GetRecords()
    if not WG_History or not WG_History.records then return {} end
    local all = WG_History.records
    local real = {}
    for _, rec in ipairs(all) do
        if not rec.debug then
            real[#real + 1] = rec
        end
    end
    return real
end

local function GetTheme()
    return WG.GetActiveTheme()
end

local function WinRGB()
    return HexToRGB(GetTheme().inlineGreen)
end

local function LossRGB()
    return HexToRGB(GetTheme().inlineLoss or "ff4444")
end

local function AccentRGB()
    return HexToRGB(GetTheme().inlineAccent)
end

-- WoW class colors fallback
local CLASS_COLORS = RAID_CLASS_COLORS or {
    WARRIOR     = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN     = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER      = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE       = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST      = { r = 1.00, g = 1.00, b = 1.00 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    SHAMAN      = { r = 0.00, g = 0.44, b = 0.87 },
    MAGE        = { r = 0.25, g = 0.78, b = 0.92 },
    WARLOCK     = { r = 0.53, g = 0.53, b = 0.93 },
    MONK        = { r = 0.00, g = 1.00, b = 0.60 },
    DRUID       = { r = 1.00, g = 0.49, b = 0.04 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER      = { r = 0.20, g = 0.58, b = 0.50 },
}

-- ---------- DATA COMPUTATION ----------

local function ComputeModeBreakdown()
    local modes = {}
    for _, rec in ipairs(GetRecords()) do
        local mt = rec.matchType or "Unknown"
        if not modes[mt] then modes[mt] = { wins = 0, losses = 0, draws = 0 } end
        if rec.result == "win" then modes[mt].wins = modes[mt].wins + 1
        elseif rec.result == "loss" then modes[mt].losses = modes[mt].losses + 1
        else modes[mt].draws = modes[mt].draws + 1 end
    end
    local result = {}
    -- Maintain a nice order
    local order = { "2v2", "3v3", "5v5", "Solo Shuffle", "BG", "Blitz" }
    for _, name in ipairs(order) do
        if modes[name] then
            table.insert(result, { name = name, wins = modes[name].wins, losses = modes[name].losses, draws = modes[name].draws })
            modes[name] = nil
        end
    end
    for name, data in pairs(modes) do
        table.insert(result, { name = name, wins = data.wins, losses = data.losses, draws = data.draws })
    end
    return result
end

local function FindSelf(rec)
    if not rec.players or not rec.playerName then return nil end
    for _, p in ipairs(rec.players) do
        if p.name and p.name == rec.playerName then return p end
    end
    -- Try prefix match
    local shortName = rec.playerName:match("^([^-]+)")
    if shortName then
        for _, p in ipairs(rec.players) do
            if p.name and p.name:match("^([^-]+)") == shortName then return p end
        end
    end
    return nil
end

local function ComputeClassMatchups()
    local classes = {}
    for _, rec in ipairs(GetRecords()) do
        if rec.players and #rec.players > 0 then
            local self = FindSelf(rec)
            local selfFaction = self and self.faction
            if selfFaction ~= nil then
                for _, p in ipairs(rec.players) do
                    if p.faction ~= selfFaction and p.classToken then
                        local ct = p.classToken
                        if not classes[ct] then classes[ct] = { wins = 0, losses = 0 } end
                        if rec.result == "win" then classes[ct].wins = classes[ct].wins + 1
                        elseif rec.result == "loss" then classes[ct].losses = classes[ct].losses + 1 end
                    end
                end
            end
        end
    end
    local result = {}
    for ct, data in pairs(classes) do
        local total = data.wins + data.losses
        local pct = total > 0 and (data.wins / total * 100) or 0
        table.insert(result, { classToken = ct, wins = data.wins, losses = data.losses, total = total, pct = pct })
    end
    table.sort(result, function(a, b) return a.pct > b.pct end)
    return result
end

local function ComputePersonalPerformance()
    local modes = {}
    local overall = { damage = 0, healing = 0, kills = 0, deaths = 0, count = 0 }
    for _, rec in ipairs(GetRecords()) do
        local self = FindSelf(rec)
        if self then
            local mt = rec.matchType or "Unknown"
            if not modes[mt] then modes[mt] = { damage = 0, healing = 0, kills = 0, deaths = 0, count = 0 } end
            local m = modes[mt]
            m.damage = m.damage + (self.damage or 0)
            m.healing = m.healing + (self.healing or 0)
            m.kills = m.kills + (self.kills or 0)
            m.deaths = m.deaths + (self.deaths or 0)
            m.count = m.count + 1
            overall.damage = overall.damage + (self.damage or 0)
            overall.healing = overall.healing + (self.healing or 0)
            overall.kills = overall.kills + (self.kills or 0)
            overall.deaths = overall.deaths + (self.deaths or 0)
            overall.count = overall.count + 1
        end
    end
    return modes, overall
end

local function ComputePeakRecords()
    local peaks = {
        damage  = { value = 0, map = "", opponent = "", date = 0 },
        healing = { value = 0, map = "", opponent = "", date = 0 },
        kills   = { value = 0, map = "", opponent = "", date = 0 },
    }
    for _, rec in ipairs(GetRecords()) do
        local self = FindSelf(rec)
        if self then
            if (self.damage or 0) > peaks.damage.value then
                peaks.damage = { value = self.damage, map = rec.map or "", opponent = rec.opponent or "", date = rec.timestamp or 0 }
            end
            if (self.healing or 0) > peaks.healing.value then
                peaks.healing = { value = self.healing, map = rec.map or "", opponent = rec.opponent or "", date = rec.timestamp or 0 }
            end
            if (self.kills or 0) > peaks.kills.value then
                peaks.kills = { value = self.kills, map = rec.map or "", opponent = rec.opponent or "", date = rec.timestamp or 0 }
            end
        end
    end
    return peaks
end

local function ComputeMapPerformance()
    local maps = {}
    for _, rec in ipairs(GetRecords()) do
        local m = rec.map or "Unknown"
        if not maps[m] then maps[m] = { wins = 0, losses = 0, draws = 0 } end
        if rec.result == "win" then maps[m].wins = maps[m].wins + 1
        elseif rec.result == "loss" then maps[m].losses = maps[m].losses + 1
        else maps[m].draws = maps[m].draws + 1 end
    end
    local result = {}
    for name, data in pairs(maps) do
        local total = data.wins + data.losses + data.draws
        local pct = total > 0 and (data.wins / total * 100) or 0
        table.insert(result, { name = name, wins = data.wins, losses = data.losses, draws = data.draws, total = total, pct = pct })
    end
    table.sort(result, function(a, b) return a.pct > b.pct end)
    return result
end

local function ComputeDurationStats()
    local total, count, minDur, maxDur = 0, 0, math.huge, 0
    local fastestWin = { duration = math.huge, map = "", opponent = "" }
    local longestMatch = { duration = 0, map = "", opponent = "" }
    local modes = {}
    for _, rec in ipairs(GetRecords()) do
        local d = rec.duration
        if d and d > 0 then
            total = total + d
            count = count + 1
            if d < minDur then minDur = d end
            if d > maxDur then maxDur = d end
            if rec.result == "win" and d < fastestWin.duration then
                fastestWin = { duration = d, map = rec.map or "", opponent = rec.opponent or "" }
            end
            if d > longestMatch.duration then
                longestMatch = { duration = d, map = rec.map or "", opponent = rec.opponent or "" }
            end
            local mt = rec.matchType or "Unknown"
            if not modes[mt] then modes[mt] = { total = 0, count = 0 } end
            modes[mt].total = modes[mt].total + d
            modes[mt].count = modes[mt].count + 1
        end
    end
    local avg = count > 0 and math.floor(total / count) or 0
    if fastestWin.duration == math.huge then fastestWin.duration = 0 end
    return {
        avg = avg, minDur = minDur ~= math.huge and minDur or 0, maxDur = maxDur,
        fastestWin = fastestWin, longestMatch = longestMatch, modes = modes
    }
end

local function ComputeTimeTrends(days)
    days = days or 14
    local now = time()
    local dayBuckets = {}
    for i = 0, days - 1 do
        local dayStart = now - (i * 86400)
        local dateKey = date("%m/%d", dayStart)
        dayBuckets[dateKey] = { wins = 0, losses = 0, order = i }
    end
    for _, rec in ipairs(GetRecords()) do
        if rec.timestamp and (now - rec.timestamp) <= (days * 86400) then
            local dateKey = date("%m/%d", rec.timestamp)
            if dayBuckets[dateKey] then
                if rec.result == "win" then dayBuckets[dateKey].wins = dayBuckets[dateKey].wins + 1
                elseif rec.result == "loss" then dayBuckets[dateKey].losses = dayBuckets[dateKey].losses + 1 end
            end
        end
    end
    local result = {}
    for key, data in pairs(dayBuckets) do
        local total = data.wins + data.losses
        local pct = total > 0 and (data.wins / total * 100) or nil
        table.insert(result, { date = key, wins = data.wins, losses = data.losses, total = total, pct = pct, order = data.order })
    end
    table.sort(result, function(a, b) return a.order > b.order end) -- oldest first
    return result
end

local function ComputeNemesisRival()
    local opponents = {}
    for _, rec in ipairs(GetRecords()) do
        local opp = rec.opponent or "Unknown"
        if not opponents[opp] then opponents[opp] = { wins = 0, losses = 0, lastMap = "", lastDate = 0 } end
        if rec.result == "win" then opponents[opp].wins = opponents[opp].wins + 1
        elseif rec.result == "loss" then opponents[opp].losses = opponents[opp].losses + 1 end
        if (rec.timestamp or 0) > opponents[opp].lastDate then
            opponents[opp].lastDate = rec.timestamp or 0
            opponents[opp].lastMap = rec.map or ""
        end
    end
    local nemesis, rival
    local maxLosses, maxWins = 0, 0
    for name, data in pairs(opponents) do
        local total = data.wins + data.losses
        if total >= 3 and data.losses > maxLosses then
            maxLosses = data.losses
            nemesis = { name = name, wins = data.wins, losses = data.losses, lastMap = data.lastMap, lastDate = data.lastDate }
        end
        if total >= 3 and data.wins > maxWins then
            maxWins = data.wins
            rival = { name = name, wins = data.wins, losses = data.losses, lastMap = data.lastMap, lastDate = data.lastDate }
        end
    end
    return nemesis, rival
end

local function ComputeSessionHistory(days)
    days = days or 14
    local now = time()
    local dayBuckets = {}
    for i = 0, days - 1 do
        local dayStart = now - (i * 86400)
        local dateKey = date("%m/%d", dayStart)
        dayBuckets[dateKey] = { wins = 0, losses = 0, order = i }
    end
    for _, rec in ipairs(GetRecords()) do
        if rec.timestamp and (now - rec.timestamp) <= (days * 86400) then
            local dateKey = date("%m/%d", rec.timestamp)
            if dayBuckets[dateKey] then
                if rec.result == "win" then dayBuckets[dateKey].wins = dayBuckets[dateKey].wins + 1
                else dayBuckets[dateKey].losses = dayBuckets[dateKey].losses + 1 end
            end
        end
    end
    local result = {}
    for key, data in pairs(dayBuckets) do
        table.insert(result, { date = key, wins = data.wins, losses = data.losses, total = data.wins + data.losses, order = data.order })
    end
    table.sort(result, function(a, b) return a.order > b.order end) -- oldest first
    return result
end

local function ComputeActivityPatterns()
    local days = {}
    local dayNames = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
    for i = 1, 7 do
        days[i] = { name = dayNames[i], wins = 0, losses = 0, total = 0 }
    end
    for _, rec in ipairs(GetRecords()) do
        if rec.timestamp then
            local wday = tonumber(date("%w", rec.timestamp)) + 1 -- Lua 1-indexed, %w is 0=Sunday
            if days[wday] then
                days[wday].total = days[wday].total + 1
                if rec.result == "win" then days[wday].wins = days[wday].wins + 1
                elseif rec.result == "loss" then days[wday].losses = days[wday].losses + 1 end
            end
        end
    end
    return days
end

-- ---------- NEW DATA COMPUTATION FUNCTIONS ----------

-- KDR per mode
local function ComputeKDRPerMode()
    local modes = {}
    for _, rec in ipairs(GetRecords()) do
        local self = FindSelf(rec)
        if self then
            local mt = rec.matchType or "Unknown"
            if not modes[mt] then modes[mt] = { kills = 0, deaths = 0, count = 0 } end
            modes[mt].kills = modes[mt].kills + (self.kills or 0)
            modes[mt].deaths = modes[mt].deaths + (self.deaths or 0)
            modes[mt].count = modes[mt].count + 1
        end
    end
    local result = {}
    local order = { "2v2", "3v3", "5v5", "Solo Shuffle", "BG", "Blitz" }
    for _, name in ipairs(order) do
        if modes[name] and modes[name].count > 0 then
            local kdr = modes[name].deaths > 0 and (modes[name].kills / modes[name].deaths) or modes[name].kills
            table.insert(result, { name = name, kills = modes[name].kills, deaths = modes[name].deaths, kdr = kdr, count = modes[name].count })
        end
    end
    return result
end

-- Damage/Healing per minute
local function ComputeEfficiency()
    local modes = {}
    local overall = { damage = 0, healing = 0, duration = 0, count = 0 }
    for _, rec in ipairs(GetRecords()) do
        local self = FindSelf(rec)
        local d = rec.duration
        if self and d and d > 0 then
            local mt = rec.matchType or "Unknown"
            if not modes[mt] then modes[mt] = { damage = 0, healing = 0, duration = 0, count = 0 } end
            modes[mt].damage = modes[mt].damage + (self.damage or 0)
            modes[mt].healing = modes[mt].healing + (self.healing or 0)
            modes[mt].duration = modes[mt].duration + d
            modes[mt].count = modes[mt].count + 1
            overall.damage = overall.damage + (self.damage or 0)
            overall.healing = overall.healing + (self.healing or 0)
            overall.duration = overall.duration + d
            overall.count = overall.count + 1
        end
    end
    return modes, overall
end

-- Best performing class combo (allied classes you win most with)
local function ComputeBestClassCombos()
    local combos = {}
    for _, rec in ipairs(GetRecords()) do
        if rec.players and #rec.players > 0 then
            local self = FindSelf(rec)
            if self and self.faction ~= nil then
                for _, p in ipairs(rec.players) do
                    if p.faction == self.faction and p.name ~= self.name and p.classToken then
                        local ct = p.classToken
                        if not combos[ct] then combos[ct] = { wins = 0, losses = 0 } end
                        if rec.result == "win" then combos[ct].wins = combos[ct].wins + 1
                        elseif rec.result == "loss" then combos[ct].losses = combos[ct].losses + 1 end
                    end
                end
            end
        end
    end
    local result = {}
    for ct, data in pairs(combos) do
        local total = data.wins + data.losses
        local pct = total > 0 and (data.wins / total * 100) or 0
        table.insert(result, { classToken = ct, wins = data.wins, losses = data.losses, total = total, pct = pct })
    end
    table.sort(result, function(a, b) return a.pct > b.pct end)
    return result
end

-- Most played opponent
local function ComputeMostPlayedOpponents()
    local opponents = {}
    for _, rec in ipairs(GetRecords()) do
        local opp = rec.opponent or "Unknown"
        if not opponents[opp] then opponents[opp] = { wins = 0, losses = 0, draws = 0, total = 0 } end
        opponents[opp].total = opponents[opp].total + 1
        if rec.result == "win" then opponents[opp].wins = opponents[opp].wins + 1
        elseif rec.result == "loss" then opponents[opp].losses = opponents[opp].losses + 1
        else opponents[opp].draws = opponents[opp].draws + 1 end
    end
    local result = {}
    for name, data in pairs(opponents) do
        table.insert(result, { name = name, wins = data.wins, losses = data.losses, draws = data.draws, total = data.total })
    end
    table.sort(result, function(a, b) return a.total > b.total end)
    return result
end

-- Opponent class distribution
local function ComputeOpponentClassDistribution()
    local classes = {}
    for _, rec in ipairs(GetRecords()) do
        if rec.players and #rec.players > 0 then
            local self = FindSelf(rec)
            if self and self.faction ~= nil then
                for _, p in ipairs(rec.players) do
                    if p.faction ~= self.faction and p.classToken then
                        local ct = p.classToken
                        if not classes[ct] then classes[ct] = { count = 0 } end
                        classes[ct].count = classes[ct].count + 1
                    end
                end
            end
        end
    end
    local result = {}
    for ct, data in pairs(classes) do
        table.insert(result, { classToken = ct, count = data.count })
    end
    table.sort(result, function(a, b) return a.count > b.count end)
    return result
end

-- New vs repeat opponents
local function ComputeNewVsRepeat()
    local seen = {}
    local newCount, repeatCount = 0, 0
    -- Records are newest-first, so iterate in reverse for chronological order
    local records = GetRecords()
    for i = #records, 1, -1 do
        local opp = records[i].opponent or "Unknown"
        if seen[opp] then
            repeatCount = repeatCount + 1
        else
            newCount = newCount + 1
            seen[opp] = true
        end
    end
    return newCount, repeatCount, newCount + repeatCount
end

-- Streaks & Milestones
local function ComputeStreaks()
    local records = GetRecords()
    if #records == 0 then return nil end

    -- Current streak (records are newest-first)
    local currentType = records[1].result
    local currentLen = 0
    for _, rec in ipairs(records) do
        if rec.result == currentType then currentLen = currentLen + 1
        else break end
    end

    -- Longest win/loss streaks ever
    local longestWin, longestLoss = 0, 0
    local streak, streakType = 0, nil
    for i = #records, 1, -1 do
        local r = records[i].result
        if r == streakType then
            streak = streak + 1
        else
            streakType = r
            streak = 1
        end
        if streakType == "win" and streak > longestWin then longestWin = streak end
        if streakType == "loss" and streak > longestLoss then longestLoss = streak end
    end

    -- Milestones
    local totalWins, totalLosses, totalDraws = 0, 0, 0
    local firstDate, lastDate = math.huge, 0
    for _, rec in ipairs(records) do
        if rec.result == "win" then totalWins = totalWins + 1
        elseif rec.result == "loss" then totalLosses = totalLosses + 1
        else totalDraws = totalDraws + 1 end
        if rec.timestamp then
            if rec.timestamp < firstDate then firstDate = rec.timestamp end
            if rec.timestamp > lastDate then lastDate = rec.timestamp end
        end
    end

    return {
        currentType = currentType, currentLen = currentLen,
        longestWin = longestWin, longestLoss = longestLoss,
        totalWins = totalWins, totalLosses = totalLosses, totalDraws = totalDraws,
        totalMatches = #records,
        firstDate = firstDate ~= math.huge and firstDate or 0,
        lastDate = lastDate,
    }
end

-- Comeback stat: win rate after being on a 3+ loss streak
local function ComputeComebackStat()
    local records = GetRecords()
    if #records < 4 then return nil end

    local afterStreakWins, afterStreakTotal = 0, 0
    -- Iterate chronologically (records are newest-first)
    for i = #records - 3, 1, -1 do
        -- Check if the 3 matches before this one were all losses
        local allLosses = true
        for j = 1, 3 do
            if records[i + j] and records[i + j].result ~= "loss" then
                allLosses = false
                break
            end
        end
        if allLosses then
            afterStreakTotal = afterStreakTotal + 1
            if records[i].result == "win" then afterStreakWins = afterStreakWins + 1 end
        end
    end

    if afterStreakTotal == 0 then return nil end
    return { wins = afterStreakWins, total = afterStreakTotal, pct = math.floor(afterStreakWins / afterStreakTotal * 100) }
end

-- Average match duration per map
local function ComputeMapDurations()
    local maps = {}
    for _, rec in ipairs(GetRecords()) do
        local m = rec.map or "Unknown"
        local d = rec.duration
        if d and d > 0 then
            if not maps[m] then maps[m] = { total = 0, count = 0 } end
            maps[m].total = maps[m].total + d
            maps[m].count = maps[m].count + 1
        end
    end
    local result = {}
    for name, data in pairs(maps) do
        local avg = math.floor(data.total / data.count)
        table.insert(result, { name = name, avg = avg, count = data.count })
    end
    table.sort(result, function(a, b) return a.avg > b.avg end)
    return result
end

-- Session analysis (group matches with <30min gaps)
local function ComputeSessionAnalysis()
    local records = GetRecords()
    if #records == 0 then return nil end

    local SESSION_GAP = 1800 -- 30 minutes
    local sessions = {}
    local currentSession = { start = 0, finish = 0, matches = 0, wins = 0, losses = 0 }

    -- Iterate chronologically
    for i = #records, 1, -1 do
        local rec = records[i]
        local ts = rec.timestamp or 0
        if currentSession.matches == 0 then
            currentSession = { start = ts, finish = ts, matches = 1, wins = 0, losses = 0 }
            if rec.result == "win" then currentSession.wins = 1
            elseif rec.result == "loss" then currentSession.losses = 1 end
        elseif ts - currentSession.finish <= SESSION_GAP then
            currentSession.finish = ts
            currentSession.matches = currentSession.matches + 1
            if rec.result == "win" then currentSession.wins = currentSession.wins + 1
            elseif rec.result == "loss" then currentSession.losses = currentSession.losses + 1 end
        else
            table.insert(sessions, currentSession)
            currentSession = { start = ts, finish = ts, matches = 1, wins = 0, losses = 0 }
            if rec.result == "win" then currentSession.wins = 1
            elseif rec.result == "loss" then currentSession.losses = 1 end
        end
    end
    if currentSession.matches > 0 then table.insert(sessions, currentSession) end

    if #sessions == 0 then return nil end

    local totalDuration, totalMatches = 0, 0
    for _, s in ipairs(sessions) do
        totalDuration = totalDuration + (s.finish - s.start)
        totalMatches = totalMatches + s.matches
    end

    return {
        sessionCount = #sessions,
        avgLength = math.floor(totalDuration / #sessions),
        avgMatches = string.format("%.1f", totalMatches / #sessions),
        sessions = sessions,
    }
end

-- Win rate by match number in session
local function ComputeWinRateByMatchInSession()
    local records = GetRecords()
    if #records == 0 then return {} end

    local SESSION_GAP_TIME = 1800
    local slots = {} -- slots[matchNum] = {wins, total}

    local sessionMatchNum = 0
    local lastTs = 0

    -- Iterate chronologically
    for i = #records, 1, -1 do
        local rec = records[i]
        local ts = rec.timestamp or 0
        if sessionMatchNum == 0 or (ts - lastTs) > SESSION_GAP_TIME then
            sessionMatchNum = 1
        else
            sessionMatchNum = sessionMatchNum + 1
        end
        lastTs = ts

        if not slots[sessionMatchNum] then slots[sessionMatchNum] = { wins = 0, total = 0 } end
        slots[sessionMatchNum].total = slots[sessionMatchNum].total + 1
        if rec.result == "win" then slots[sessionMatchNum].wins = slots[sessionMatchNum].wins + 1 end
    end

    local result = {}
    for num, data in pairs(slots) do
        if num <= 15 then -- cap at 15 to keep chart reasonable
            local pct = data.total > 0 and math.floor(data.wins / data.total * 100) or 0
            table.insert(result, { matchNum = num, wins = data.wins, total = data.total, pct = pct })
        end
    end
    table.sort(result, function(a, b) return a.matchNum < b.matchNum end)
    return result
end

-- Head-to-Head top 5 most played
local function ComputeHeadToHead()
    local opponents = {}
    for _, rec in ipairs(GetRecords()) do
        local opp = rec.opponent or "Unknown"
        if not opponents[opp] then opponents[opp] = { wins = 0, losses = 0, draws = 0, totalDmg = 0, totalHeal = 0, dmgCount = 0, favMap = {}, lastDate = 0 } end
        local o = opponents[opp]
        if rec.result == "win" then o.wins = o.wins + 1
        elseif rec.result == "loss" then o.losses = o.losses + 1
        else o.draws = o.draws + 1 end

        local self = FindSelf(rec)
        if self then
            o.totalDmg = o.totalDmg + (self.damage or 0)
            o.totalHeal = o.totalHeal + (self.healing or 0)
            o.dmgCount = o.dmgCount + 1
        end

        local m = rec.map or "Unknown"
        o.favMap[m] = (o.favMap[m] or 0) + 1
        if (rec.timestamp or 0) > o.lastDate then o.lastDate = rec.timestamp or 0 end
    end

    local result = {}
    for name, data in pairs(opponents) do
        local total = data.wins + data.losses + data.draws
        -- Find favorite map
        local topMap, topMapCount = "", 0
        for m, c in pairs(data.favMap) do
            if c > topMapCount then topMap = m; topMapCount = c end
        end
        local avgDmg = data.dmgCount > 0 and math.floor(data.totalDmg / data.dmgCount) or 0
        local avgHeal = data.dmgCount > 0 and math.floor(data.totalHeal / data.dmgCount) or 0
        table.insert(result, {
            name = name, wins = data.wins, losses = data.losses, draws = data.draws,
            total = total, avgDmg = avgDmg, avgHeal = avgHeal, favMap = topMap, lastDate = data.lastDate,
        })
    end
    table.sort(result, function(a, b) return a.total > b.total end)

    -- Return top 5
    local top5 = {}
    for i = 1, math.min(5, #result) do
        table.insert(top5, result[i])
    end
    return top5
end

-- ---------- FRAME STATE ----------
local advFrame
local scrollContent
local advTabStrip
local activeGroup = "overview"
local chartFramePool = {}
local RefreshAdvancedStats -- forward declaration; CreateAdvancedFrame's tab strip
                            -- closure references it before its definition below

local function RecycleChildren(parent)
    local children = { parent:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:ClearAllPoints()
        child:SetParent(nil)
    end
    -- Clear font strings too
    local regions = { parent:GetRegions() }
    for _, region in ipairs(regions) do
        if region ~= parent._bg then
            region:Hide()
            region:SetParent(nil)
        end
    end
end

-- ---------- CHART PRIMITIVES ----------

local function CreateLabel(parent, text, size, x, y, r, g, b, justifyH)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(FONT, size or 11, "")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetTextColor(r or 0.8, g or 0.8, b or 0.8)
    fs:SetText(text)
    if justifyH then fs:SetJustifyH(justifyH) end
    return fs
end

local function CreateSectionHeader(parent, title, yOffset)
    local t = GetTheme()
    local ar, ag, ab = AccentRGB()

    -- Section title
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetFont(FONT, 14, "")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOffset)
    header:SetTextColor(ar, ag, ab)
    header:SetText(title)

    WG.RegisterThemedElement(header, function(fs)
        local nar, nag, nab = AccentRGB()
        fs:SetTextColor(nar, nag, nab)
    end)

    -- Separator line
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, yOffset - 18)
    sep:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD, yOffset - 18)
    sep:SetColorTexture(ar, ag, ab, 0.3)

    WG.RegisterThemedElement(sep, function(tex)
        local nar, nag, nab = AccentRGB()
        tex:SetColorTexture(nar, nag, nab, 0.3)
    end)

    return yOffset - 28
end

local function CreateNoDataLabel(parent, yOffset)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(FONT, 11, "")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD + 10, yOffset)
    fs:SetTextColor(0.5, 0.5, 0.5)
    fs:SetText("No data yet")
    return yOffset - 25
end

-- Vertical bar chart: data = {{label, value, value2(optional), color, color2(optional)}}
local function DrawVerticalBarChart(parent, data, x, y, width, height, config)
    config = config or {}
    local grouped = config.grouped -- if true, each entry has value (win) and value2 (loss)
    local maxVal = 0
    for _, d in ipairs(data) do
        if grouped then
            maxVal = math.max(maxVal, (d.value or 0), (d.value2 or 0))
        else
            maxVal = math.max(maxVal, d.value or 0)
        end
    end
    if maxVal == 0 then maxVal = 1 end

    local numBars = #data
    local barSpacing = 4
    local groupWidth = grouped and 2 or 1
    local totalBarSlots = numBars * groupWidth + (grouped and numBars or 0)
    local barW = math.max(6, math.floor((width - (numBars - 1) * barSpacing * 2) / (numBars * groupWidth + (grouped and numBars * 0.5 or 0))))
    barW = math.min(barW, 40)
    local groupW = grouped and (barW * 2 + 2) or barW
    local totalW = numBars * groupW + (numBars - 1) * barSpacing
    local startX = x + math.floor((width - totalW) / 2)

    -- Y axis line
    local yAxis = parent:CreateTexture(nil, "ARTWORK")
    yAxis:SetSize(1, height)
    yAxis:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    yAxis:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    -- X axis line
    local xAxis = parent:CreateTexture(nil, "ARTWORK")
    xAxis:SetSize(width, 1)
    xAxis:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - height)
    xAxis:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    for i, d in ipairs(data) do
        local bx = startX + (i - 1) * (groupW + barSpacing)

        if grouped then
            -- Win bar
            local h1 = math.max(2, math.floor((d.value or 0) / maxVal * (height - 20)))
            local bar1 = CreateFrame("Frame", nil, parent)
            bar1:SetSize(barW, h1)
            bar1:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", bx, y - height)
            local bg1 = bar1:CreateTexture(nil, "ARTWORK")
            bg1:SetAllPoints()
            local wr, wg, wb = WinRGB()
            bg1:SetColorTexture(wr, wg, wb, 0.85)
            WG.RegisterThemedElement(bg1, function(tex)
                local nr, ng, nb = WinRGB()
                tex:SetColorTexture(nr, ng, nb, 0.85)
            end)

            -- Loss bar
            local h2 = math.max(2, math.floor((d.value2 or 0) / maxVal * (height - 20)))
            local bar2 = CreateFrame("Frame", nil, parent)
            bar2:SetSize(barW, h2)
            bar2:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", bx + barW + 2, y - height)
            local bg2 = bar2:CreateTexture(nil, "ARTWORK")
            bg2:SetAllPoints()
            local lr, lg, lb = LossRGB()
            bg2:SetColorTexture(lr, lg, lb, 0.85)
            WG.RegisterThemedElement(bg2, function(tex)
                local nr, ng, nb = LossRGB()
                tex:SetColorTexture(nr, ng, nb, 0.85)
            end)

            -- Win rate label above
            local total = (d.value or 0) + (d.value2 or 0)
            if total > 0 then
                local pct = math.floor((d.value or 0) / total * 100)
                local pctLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                pctLabel:SetFont(FONT, 9, "")
                pctLabel:SetPoint("BOTTOM", bar1, "TOP", barW / 2 + 1, 2)
                pctLabel:SetTextColor(0.8, 0.8, 0.8)
                pctLabel:SetText(pct .. "%")
            end
        else
            local h = math.max(2, math.floor((d.value or 0) / maxVal * (height - 20)))
            local bar = CreateFrame("Frame", nil, parent)
            bar:SetSize(barW, h)
            bar:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", bx, y - height)
            local bg = bar:CreateTexture(nil, "ARTWORK")
            bg:SetAllPoints()
            if d.color then
                bg:SetColorTexture(d.color[1], d.color[2], d.color[3], d.color[4] or 0.85)
            else
                local ar, ag, ab = AccentRGB()
                bg:SetColorTexture(ar, ag, ab, 0.85)
            end

            -- Value label
            if (d.value or 0) > 0 then
                local valLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                valLabel:SetFont(FONT, 9, "")
                valLabel:SetPoint("BOTTOM", bar, "TOP", 0, 2)
                valLabel:SetTextColor(0.8, 0.8, 0.8)
                valLabel:SetText(d.topLabel or tostring(d.value))
            end
        end

        -- Bottom label
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetFont(FONT, 9, "")
        label:SetPoint("TOP", parent, "TOPLEFT", bx + groupW / 2, y - height - 2)
        label:SetTextColor(0.6, 0.6, 0.6)
        label:SetText(d.label or "")
    end
end

-- Horizontal bar chart: data = {{label, value, maxValue, color, rightLabel}}
local function DrawHorizontalBarChart(parent, data, x, y, width, config)
    config = config or {}
    local barH = config.barHeight or BAR_HEIGHT
    local spacing = config.spacing or 4
    local labelWidth = config.labelWidth or 120
    local maxVal = 0
    for _, d in ipairs(data) do
        maxVal = math.max(maxVal, d.value or 0)
    end
    if maxVal == 0 then maxVal = 1 end
    local barAreaW = width - labelWidth - 80

    for i, d in ipairs(data) do
        local by = y - (i - 1) * (barH + spacing)

        -- Label
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetFont(FONT, 10, "")
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, by)
        label:SetWidth(labelWidth - 5)
        label:SetJustifyH("RIGHT")
        if d.labelColor then
            label:SetTextColor(d.labelColor[1], d.labelColor[2], d.labelColor[3])
        else
            label:SetTextColor(0.8, 0.8, 0.8)
        end
        label:SetText(d.label or "")

        -- Bar background
        local bgBar = CreateFrame("Frame", nil, parent)
        bgBar:SetSize(barAreaW, barH - 2)
        bgBar:SetPoint("TOPLEFT", parent, "TOPLEFT", x + labelWidth, by - 1)
        local bgTex = bgBar:CreateTexture(nil, "BACKGROUND")
        bgTex:SetAllPoints()
        bgTex:SetColorTexture(0.15, 0.15, 0.15, 0.5)

        -- Value bar
        local barW = math.max(2, math.floor((d.value or 0) / maxVal * barAreaW))
        local bar = CreateFrame("Frame", nil, parent)
        bar:SetSize(barW, barH - 2)
        bar:SetPoint("TOPLEFT", parent, "TOPLEFT", x + labelWidth, by - 1)
        local barTex = bar:CreateTexture(nil, "ARTWORK")
        barTex:SetAllPoints()
        if d.color then
            barTex:SetColorTexture(d.color[1], d.color[2], d.color[3], d.color[4] or 0.8)
        else
            local ar, ag, ab = AccentRGB()
            barTex:SetColorTexture(ar, ag, ab, 0.8)
        end

        -- Right label
        local rightLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rightLabel:SetFont(FONT, 10, "")
        rightLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", x + labelWidth + barAreaW + 5, by)
        rightLabel:SetTextColor(0.7, 0.7, 0.7)
        rightLabel:SetText(d.rightLabel or "")
    end

    return y - #data * (barH + spacing)
end

-- Line chart with dots
local function DrawLineChart(parent, data, x, y, width, height, config)
    config = config or {}
    if #data == 0 then return end

    -- Background
    local bg = CreateFrame("Frame", nil, parent)
    bg:SetSize(width, height)
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local bgTex = bg:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints()
    bgTex:SetColorTexture(0.08, 0.08, 0.08, 0.4)

    -- Grid lines (25%, 50%, 75%)
    for _, pct in ipairs({ 0.25, 0.5, 0.75 }) do
        local gridY = y - height + math.floor(height * pct)
        local grid = parent:CreateTexture(nil, "ARTWORK")
        grid:SetSize(width, 1)
        grid:SetPoint("TOPLEFT", parent, "TOPLEFT", x, gridY)
        grid:SetColorTexture(0.25, 0.25, 0.25, 0.4)

        local gridLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        gridLabel:SetFont(FONT, 8, "")
        gridLabel:SetPoint("TOPRIGHT", parent, "TOPLEFT", x - 3, gridY + 4)
        gridLabel:SetTextColor(0.4, 0.4, 0.4)
        gridLabel:SetText(tostring(math.floor((1 - pct) * 100)) .. "%")
    end

    -- 0% and 100% labels
    local topLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    topLabel:SetFont(FONT, 8, "")
    topLabel:SetPoint("TOPRIGHT", parent, "TOPLEFT", x - 3, y + 4)
    topLabel:SetTextColor(0.4, 0.4, 0.4)
    topLabel:SetText("100%")

    local botLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    botLabel:SetFont(FONT, 8, "")
    botLabel:SetPoint("TOPRIGHT", parent, "TOPLEFT", x - 3, y - height + 4)
    botLabel:SetTextColor(0.4, 0.4, 0.4)
    botLabel:SetText("0%")

    -- Plot points
    local stepX = #data > 1 and (width / (#data - 1)) or 0
    local DOT_SIZE = 4
    local ar, ag, ab = AccentRGB()
    local prevDotX, prevDotY

    for i, d in ipairs(data) do
        if d.pct ~= nil then
            local dotX = x + (i - 1) * stepX
            local dotY = y - height + math.floor(d.pct / 100 * height)

            -- Data point dot
            local dot = parent:CreateTexture(nil, "OVERLAY")
            dot:SetSize(DOT_SIZE, DOT_SIZE)
            dot:SetPoint("CENTER", parent, "TOPLEFT", dotX, dotY)
            dot:SetColorTexture(ar, ag, ab, 1)
            WG.RegisterThemedElement(dot, function(tex)
                local nar, nag, nab = AccentRGB()
                tex:SetColorTexture(nar, nag, nab, 1)
            end)

            -- Interpolated dots between points
            if prevDotX and prevDotY then
                local dist = math.sqrt((dotX - prevDotX)^2 + (dotY - prevDotY)^2)
                local steps = math.floor(dist / 3)
                for s = 1, steps - 1 do
                    local frac = s / steps
                    local ix = prevDotX + (dotX - prevDotX) * frac
                    local iy = prevDotY + (dotY - prevDotY) * frac
                    local idot = parent:CreateTexture(nil, "OVERLAY")
                    idot:SetSize(2, 2)
                    idot:SetPoint("CENTER", parent, "TOPLEFT", ix, iy)
                    idot:SetColorTexture(ar, ag, ab, 0.5)
                    WG.RegisterThemedElement(idot, function(tex)
                        local nar, nag, nab = AccentRGB()
                        tex:SetColorTexture(nar, nag, nab, 0.5)
                    end)
                end
            end

            prevDotX, prevDotY = dotX, dotY
        else
            prevDotX, prevDotY = nil, nil
        end

        -- X-axis date label (every few entries)
        if #data <= 14 or (i % math.ceil(#data / 7) == 0) or i == 1 or i == #data then
            local dateLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dateLabel:SetFont(FONT, 8, "")
            dateLabel:SetPoint("TOP", parent, "TOPLEFT", x + (i - 1) * stepX, y - height - 2)
            dateLabel:SetTextColor(0.4, 0.4, 0.4)
            dateLabel:SetText(d.date or "")
        end
    end
end

-- Stat card
local function CreateStatCard(parent, title, value, subtitle, x, y, w)
    local cardWidth = w or CARD_W
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(cardWidth, CARD_H)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    WG.ApplyModernStyle(card)

    local ar, ag, ab = AccentRGB()

    local valFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valFS:SetFont(FONT, 20, "")
    valFS:SetPoint("TOP", card, "TOP", 0, -8)
    valFS:SetTextColor(ar, ag, ab)
    valFS:SetText(value or "—")
    WG.RegisterThemedElement(valFS, function(fs)
        local nar, nag, nab = AccentRGB()
        fs:SetTextColor(nar, nag, nab)
    end)

    local titleFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFS:SetFont(FONT, 11, "")
    titleFS:SetPoint("TOP", valFS, "BOTTOM", 0, -4)
    titleFS:SetTextColor(0.9, 0.9, 0.9)
    titleFS:SetText(title or "")

    if subtitle then
        local subFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subFS:SetFont(FONT, 9, "")
        subFS:SetPoint("TOP", titleFS, "BOTTOM", 0, -2)
        subFS:SetTextColor(0.5, 0.5, 0.5)
        subFS:SetText(subtitle)
        subFS:SetWidth(cardWidth - 10)
        subFS:SetJustifyH("CENTER")
    end

    return card
end

-- ---------- SECTION RENDERERS ----------

-- 1. Game Mode Breakdown
local function RenderModeBreakdown(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Game Mode Breakdown", yOffset)
    local data = ComputeModeBreakdown()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        table.insert(chartData, { label = d.name, value = d.wins, value2 = d.losses })
    end
    DrawVerticalBarChart(parent, chartData, PAD + 5, yOffset - 5, CONTENT_W - PAD * 2 - 10, 140, { grouped = true })

    -- Legend
    local wr, wg, wb = WinRGB()
    local lr, lg, lb = LossRGB()
    local winLeg = parent:CreateTexture(nil, "ARTWORK")
    winLeg:SetSize(10, 10)
    winLeg:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_W - 120, yOffset - 5)
    winLeg:SetColorTexture(wr, wg, wb, 0.85)
    local winLabel = CreateLabel(parent, "Wins", 9, CONTENT_W - 107, yOffset - 4, 0.7, 0.7, 0.7)

    local lossLeg = parent:CreateTexture(nil, "ARTWORK")
    lossLeg:SetSize(10, 10)
    lossLeg:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_W - 120, yOffset - 20)
    lossLeg:SetColorTexture(lr, lg, lb, 0.85)
    local lossLabel = CreateLabel(parent, "Losses", 9, CONTENT_W - 107, yOffset - 19, 0.7, 0.7, 0.7)

    return yOffset - 175 - SECTION_GAP
end

-- 2. Class Matchup Stats
local function RenderClassMatchups(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Class Matchup Stats", yOffset)
    local data = ComputeClassMatchups()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        local cc = CLASS_COLORS[d.classToken]
        local className = d.classToken:sub(1, 1) .. d.classToken:sub(2):lower()
        className = className:gsub("knight", " Knight"):gsub("hunter", " Hunter"):gsub("lock", "lock"):gsub("walker", "walker")
        local labelColor = cc and { cc.r, cc.g, cc.b } or { 0.8, 0.8, 0.8 }
        local barColor = cc and { cc.r, cc.g, cc.b, 0.8 } or nil
        table.insert(chartData, {
            label = className,
            value = d.pct,
            color = barColor,
            labelColor = labelColor,
            rightLabel = string.format("%dW-%dL (%.0f%%)", d.wins, d.losses, d.pct),
        })
    end

    local endY = DrawHorizontalBarChart(parent, chartData, PAD, yOffset - 5, CONTENT_W - PAD * 2, { labelWidth = 110, barHeight = 16, spacing = 3 })
    return endY - SECTION_GAP
end

-- 3. Personal Performance
local function RenderPersonalPerformance(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Personal Performance", yOffset)
    local modes, overall = ComputePersonalPerformance()
    if overall.count == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    -- Overall averages as stat cards
    local avgDmg = math.floor(overall.damage / overall.count)
    local avgHeal = math.floor(overall.healing / overall.count)
    local avgKills = string.format("%.1f", overall.kills / overall.count)
    local avgDeaths = string.format("%.1f", overall.deaths / overall.count)

    local cardY = yOffset - 5
    local cardSpacing = CARD_W + 15
    local startX = math.floor((CONTENT_W - 4 * cardSpacing + 15) / 2)

    CreateStatCard(parent, "Avg Damage", FormatNumber(avgDmg), overall.count .. " matches", startX, cardY)
    CreateStatCard(parent, "Avg Healing", FormatNumber(avgHeal), nil, startX + cardSpacing, cardY)
    CreateStatCard(parent, "Avg Kills", avgKills, nil, startX + cardSpacing * 2, cardY)
    CreateStatCard(parent, "Avg Deaths", avgDeaths, nil, startX + cardSpacing * 3, cardY)

    return cardY - CARD_H - 10 - SECTION_GAP
end

-- 4. Peak Records
local function RenderPeakRecords(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Peak Records", yOffset)
    local peaks = ComputePeakRecords()

    if peaks.damage.value == 0 and peaks.healing.value == 0 and peaks.kills.value == 0 then
        return CreateNoDataLabel(parent, yOffset) - SECTION_GAP
    end

    local cardY = yOffset - 5
    local cardSpacing = (CONTENT_W - PAD * 2) / 3
    local cardW2 = cardSpacing - 10

    local items = {
        { title = "Highest Damage", peak = peaks.damage },
        { title = "Highest Healing", peak = peaks.healing },
        { title = "Most Kills", peak = peaks.kills },
    }

    for i, item in ipairs(items) do
        local cx = PAD + (i - 1) * cardSpacing
        local sub = ""
        if item.peak.map ~= "" then sub = sub .. item.peak.map end
        if item.peak.opponent ~= "" then sub = sub .. " vs " .. item.peak.opponent end
        if item.peak.date > 0 then sub = sub .. "\n" .. date("%m/%d/%y", item.peak.date) end

        local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card:SetSize(cardW2, CARD_H + 10)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", cx, cardY)
        WG.ApplyModernStyle(card)

        local ar, ag, ab = AccentRGB()
        local valFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valFS:SetFont(FONT, 20, "")
        valFS:SetPoint("TOP", card, "TOP", 0, -6)
        valFS:SetTextColor(ar, ag, ab)
        valFS:SetText(FormatNumber(item.peak.value))
        WG.RegisterThemedElement(valFS, function(fs) local r2, g2, b2 = AccentRGB(); fs:SetTextColor(r2, g2, b2) end)

        local titleFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFS:SetFont(FONT, 11, "")
        titleFS:SetPoint("TOP", valFS, "BOTTOM", 0, -3)
        titleFS:SetTextColor(0.9, 0.9, 0.9)
        titleFS:SetText(item.title)

        local subFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subFS:SetFont(FONT, 9, "")
        subFS:SetPoint("TOP", titleFS, "BOTTOM", 0, -2)
        subFS:SetWidth(cardW2 - 10)
        subFS:SetJustifyH("CENTER")
        subFS:SetTextColor(0.5, 0.5, 0.5)
        subFS:SetText(sub)
    end

    return cardY - CARD_H - 20 - SECTION_GAP
end

-- 5. Map Performance
local function RenderMapPerformance(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Map Performance", yOffset)
    local data = ComputeMapPerformance()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        local ar, ag, ab = AccentRGB()
        table.insert(chartData, {
            label = d.name,
            value = d.pct,
            color = { ar, ag, ab, 0.8 },
            rightLabel = string.format("%dW-%dL (%.0f%%)", d.wins, d.losses, d.pct),
        })
    end

    local endY = DrawHorizontalBarChart(parent, chartData, PAD, yOffset - 5, CONTENT_W - PAD * 2, { labelWidth = 140, barHeight = 16, spacing = 3 })
    return endY - SECTION_GAP
end

-- 6. Duration Analysis
local function RenderDurationAnalysis(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Duration Analysis", yOffset)
    local stats = ComputeDurationStats()

    if stats.avg == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local cardY = yOffset - 5
    local cardSpacing = (CONTENT_W - PAD * 2) / 3
    local cardW2 = cardSpacing - 10

    -- Stat cards
    local cardItems = {
        { title = "Avg Duration", value = FormatDuration(stats.avg), subtitle = nil },
        { title = "Fastest Win", value = FormatDuration(stats.fastestWin.duration), subtitle = stats.fastestWin.map },
        { title = "Longest Match", value = FormatDuration(stats.longestMatch.duration), subtitle = stats.longestMatch.map },
    }

    for i, item in ipairs(cardItems) do
        local cx = PAD + (i - 1) * cardSpacing
        CreateStatCard(parent, item.title, item.value, item.subtitle, cx, cardY, cardW2)
    end

    -- Duration per mode bar chart
    local chartY = cardY - CARD_H - 20
    local modeData = {}
    local order = { "2v2", "3v3", "5v5", "Solo Shuffle", "BG", "Blitz" }
    for _, name in ipairs(order) do
        if stats.modes[name] then
            local avg = math.floor(stats.modes[name].total / stats.modes[name].count)
            table.insert(modeData, { label = name, value = avg, topLabel = FormatDuration(avg) })
        end
    end

    if #modeData > 0 then
        DrawVerticalBarChart(parent, modeData, PAD + 5, chartY, CONTENT_W - PAD * 2 - 10, 100, {})
        return chartY - 130 - SECTION_GAP
    end

    return chartY - SECTION_GAP
end

-- 7. Time Trends
local function RenderTimeTrends(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Win Rate Trend (Last 14 Days)", yOffset)
    local data = ComputeTimeTrends(14)

    local hasData = false
    for _, d in ipairs(data) do
        if d.pct ~= nil then hasData = true; break end
    end
    if not hasData then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    DrawLineChart(parent, data, PAD + 25, yOffset - 5, CONTENT_W - PAD * 2 - 30, 120, {})
    return yOffset - 155 - SECTION_GAP
end

-- 8. Nemesis & Rival
local function RenderNemesisRival(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Nemesis & Rival", yOffset)
    local nemesis, rival = ComputeNemesisRival()

    if not nemesis and not rival then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local cardW2 = math.floor((CONTENT_W - PAD * 2 - 10) / 2)
    local cardH2 = 95
    local cardY = yOffset - 5

    local function MakeProfileCard(parentFrame, title, data, cx, cy, isNemesis)
        if not data then
            local noData = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noData:SetFont(FONT, 10, "")
            noData:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", cx + 10, cy - 30)
            noData:SetTextColor(0.5, 0.5, 0.5)
            noData:SetText("Not enough data (3+ games needed)")
            return
        end

        local card = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        card:SetSize(cardW2, cardH2)
        card:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", cx, cy)
        WG.ApplyModernStyle(card)

        local ar, ag, ab = AccentRGB()
        local lr, lg, lb = LossRGB()
        local wr, wg, wb = WinRGB()

        -- Title
        local titleFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFS:SetFont(FONT, 12, "")
        titleFS:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
        if isNemesis then
            titleFS:SetTextColor(lr, lg, lb)
        else
            titleFS:SetTextColor(wr, wg, wb)
        end
        titleFS:SetText(title)

        -- Name
        local nameFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameFS:SetFont(FONT, 16, "")
        nameFS:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -24)
        nameFS:SetTextColor(0.95, 0.95, 0.95)
        nameFS:SetText(data.name)

        -- W-L
        local wlFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        wlFS:SetFont(FONT, 11, "")
        wlFS:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -44)
        wlFS:SetTextColor(0.7, 0.7, 0.7)
        wlFS:SetText(data.wins .. "W - " .. data.losses .. "L")

        -- Last map
        if data.lastMap ~= "" then
            local mapFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            mapFS:SetFont(FONT, 9, "")
            mapFS:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -60)
            mapFS:SetTextColor(0.5, 0.5, 0.5)
            mapFS:SetText("Last: " .. data.lastMap)
        end

        -- Date
        if data.lastDate > 0 then
            local dateFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dateFS:SetFont(FONT, 9, "")
            dateFS:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -8)
            dateFS:SetTextColor(0.4, 0.4, 0.4)
            dateFS:SetText(date("%m/%d/%y", data.lastDate))
        end

        -- Explanation text (bottom-right)
        local explainFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        explainFS:SetFont(FONT, 8, "")
        explainFS:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 6)
        explainFS:SetJustifyH("RIGHT")
        explainFS:SetTextColor(0.4, 0.4, 0.4)
        if isNemesis then
            explainFS:SetText("Opponent you've lost to the most")
        else
            explainFS:SetText("Opponent you've beaten the most")
        end
    end

    MakeProfileCard(parent, "Nemesis", nemesis, PAD, cardY, true)
    MakeProfileCard(parent, "Rival", rival, PAD + cardW2 + 10, cardY, false)

    return cardY - cardH2 - 10 - SECTION_GAP
end

-- 9. Session History
local function RenderSessionHistory(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Session History (Last 14 Days)", yOffset)
    local data = ComputeSessionHistory(14)

    local hasData = false
    for _, d in ipairs(data) do
        if d.total > 0 then hasData = true; break end
    end
    if not hasData then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        -- Stacked: show total as bar, colored by majority
        local wr, wg, wb = WinRGB()
        local lr, lg, lb = LossRGB()
        local majorWin = d.wins >= d.losses
        table.insert(chartData, {
            label = d.date,
            value = d.wins,
            value2 = d.losses,
        })
    end

    DrawVerticalBarChart(parent, chartData, PAD + 5, yOffset - 5, CONTENT_W - PAD * 2 - 10, 120, { grouped = true })
    return yOffset - 155 - SECTION_GAP
end

-- 10. Activity Patterns
local function RenderActivityPatterns(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Activity Patterns", yOffset)
    local data = ComputeActivityPatterns()

    local hasData = false
    for _, d in ipairs(data) do
        if d.total > 0 then hasData = true; break end
    end
    if not hasData then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        local pct = d.total > 0 and math.floor(d.wins / d.total * 100) or 0
        table.insert(chartData, {
            label = d.name,
            value = d.total,
            topLabel = d.total > 0 and (d.total .. " (" .. pct .. "%)") or "0",
        })
    end

    DrawVerticalBarChart(parent, chartData, PAD + 5, yOffset - 5, CONTENT_W - PAD * 2 - 10, 120, {})
    return yOffset - 155 - SECTION_GAP
end

-- 11. KDR Per Mode
local function RenderKDRPerMode(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Kill/Death Ratio by Mode", yOffset)
    local data = ComputeKDRPerMode()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        table.insert(chartData, {
            label = d.name,
            value = d.kdr * 100, -- scale for bar display
            topLabel = string.format("%.2f", d.kdr),
        })
    end
    DrawVerticalBarChart(parent, chartData, PAD + 5, yOffset - 5, CONTENT_W - PAD * 2 - 10, 120, {})

    -- Summary cards
    local totalK, totalD = 0, 0
    for _, d in ipairs(data) do totalK = totalK + d.kills; totalD = totalD + d.deaths end
    local overallKDR = totalD > 0 and (totalK / totalD) or totalK
    local summaryFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryFS:SetFont(FONT, 10, "")
    summaryFS:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_W - 180, yOffset - 5)
    summaryFS:SetTextColor(0.7, 0.7, 0.7)
    summaryFS:SetText("Overall: " .. string.format("%.2f", overallKDR) .. " KDR\n" .. totalK .. " kills / " .. totalD .. " deaths")

    return yOffset - 155 - SECTION_GAP
end

-- 12. Damage/Healing Per Minute
local function RenderEfficiency(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Damage & Healing Per Minute", yOffset)
    local modes, overall = ComputeEfficiency()
    if overall.count == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local overallDPM = overall.duration > 0 and math.floor(overall.damage / (overall.duration / 60)) or 0
    local overallHPM = overall.duration > 0 and math.floor(overall.healing / (overall.duration / 60)) or 0

    local cardY = yOffset - 5
    local cardSpacing = (CONTENT_W - PAD * 2) / 2
    local cardW2 = cardSpacing - 10
    CreateStatCard(parent, "Avg DPM", FormatNumber(overallDPM), overall.count .. " matches", PAD, cardY, cardW2)
    CreateStatCard(parent, "Avg HPM", FormatNumber(overallHPM), nil, PAD + cardSpacing, cardY, cardW2)

    -- Per-mode breakdown
    local chartY = cardY - CARD_H - 15
    local chartData = {}
    local order = { "2v2", "3v3", "5v5", "Solo Shuffle", "BG", "Blitz" }
    for _, name in ipairs(order) do
        local m = modes[name]
        if m and m.duration > 0 then
            local dpm = math.floor(m.damage / (m.duration / 60))
            table.insert(chartData, { label = name, value = dpm, topLabel = FormatNumber(dpm) })
        end
    end
    if #chartData > 0 then
        local subHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subHeader:SetFont(FONT, 10, "")
        subHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, chartY + 2)
        subHeader:SetTextColor(0.6, 0.6, 0.6)
        subHeader:SetText("DPM by Mode")
        DrawVerticalBarChart(parent, chartData, PAD + 5, chartY - 12, CONTENT_W - PAD * 2 - 10, 100, {})
        return chartY - 145 - SECTION_GAP
    end

    return cardY - CARD_H - 10 - SECTION_GAP
end

-- 13. Best Performing Class Combo
local function RenderClassCombos(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Best Teammate Classes", yOffset)
    local data = ComputeBestClassCombos()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        local cc = CLASS_COLORS[d.classToken]
        local className = d.classToken:sub(1, 1) .. d.classToken:sub(2):lower()
        className = className:gsub("knight", " Knight"):gsub("hunter", " Hunter")
        local labelColor = cc and { cc.r, cc.g, cc.b } or { 0.8, 0.8, 0.8 }
        local barColor = cc and { cc.r, cc.g, cc.b, 0.8 } or nil
        table.insert(chartData, {
            label = className, value = d.pct, color = barColor, labelColor = labelColor,
            rightLabel = string.format("%dW-%dL (%.0f%%)", d.wins, d.losses, d.pct),
        })
    end
    local endY = DrawHorizontalBarChart(parent, chartData, PAD, yOffset - 5, CONTENT_W - PAD * 2, { labelWidth = 110, barHeight = 16, spacing = 3 })
    return endY - SECTION_GAP
end

-- 14. Most Played Opponents
local function RenderMostPlayed(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Most Played Opponents", yOffset)
    local data = ComputeMostPlayedOpponents()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    local count = math.min(10, #data)
    for i = 1, count do
        local d = data[i]
        local wr = d.total > 0 and math.floor(d.wins / d.total * 100) or 0
        table.insert(chartData, {
            label = d.name, value = d.total,
            rightLabel = string.format("%d games  %dW-%dL (%d%%)", d.total, d.wins, d.losses, wr),
        })
    end
    local endY = DrawHorizontalBarChart(parent, chartData, PAD, yOffset - 5, CONTENT_W - PAD * 2, { labelWidth = 130, barHeight = 16, spacing = 3 })
    return endY - SECTION_GAP
end

-- 15. Opponent Class Distribution
local function RenderOpponentClassDist(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Opponent Class Distribution", yOffset)
    local data = ComputeOpponentClassDistribution()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local totalCount = 0
    for _, d in ipairs(data) do totalCount = totalCount + d.count end

    local chartData = {}
    for _, d in ipairs(data) do
        local cc = CLASS_COLORS[d.classToken]
        local className = d.classToken:sub(1, 1) .. d.classToken:sub(2):lower()
        className = className:gsub("knight", " Knight"):gsub("hunter", " Hunter")
        local labelColor = cc and { cc.r, cc.g, cc.b } or { 0.8, 0.8, 0.8 }
        local barColor = cc and { cc.r, cc.g, cc.b, 0.8 } or nil
        local pct = totalCount > 0 and math.floor(d.count / totalCount * 100) or 0
        table.insert(chartData, {
            label = className, value = d.count, color = barColor, labelColor = labelColor,
            rightLabel = d.count .. " (" .. pct .. "%)",
        })
    end
    local endY = DrawHorizontalBarChart(parent, chartData, PAD, yOffset - 5, CONTENT_W - PAD * 2, { labelWidth = 110, barHeight = 16, spacing = 3 })
    return endY - SECTION_GAP
end

-- 16. New vs Repeat Opponents
local function RenderNewVsRepeat(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "New vs Repeat Opponents", yOffset)
    local newCount, repeatCount, totalCount = ComputeNewVsRepeat()
    if totalCount == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local cardY = yOffset - 5
    local cardSpacing = (CONTENT_W - PAD * 2) / 3
    local cardW2 = cardSpacing - 10
    local newPct = totalCount > 0 and math.floor(newCount / totalCount * 100) or 0
    local repPct = totalCount > 0 and math.floor(repeatCount / totalCount * 100) or 0

    CreateStatCard(parent, "Unique Opponents", tostring(newCount), newPct .. "% of matches", PAD, cardY, cardW2)
    CreateStatCard(parent, "Rematches", tostring(repeatCount), repPct .. "% of matches", PAD + cardSpacing, cardY, cardW2)
    CreateStatCard(parent, "Total Matches", tostring(totalCount), nil, PAD + cardSpacing * 2, cardY, cardW2)

    return cardY - CARD_H - 10 - SECTION_GAP
end

-- 17. Streaks & Milestones
local function RenderStreaksMilestones(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Streaks & Milestones", yOffset)
    local data = ComputeStreaks()
    if not data then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local cardY = yOffset - 5
    local cardSpacing = (CONTENT_W - PAD * 2) / 4
    local cardW2 = cardSpacing - 8

    -- Current streak
    local streakText = data.currentLen .. " " .. (data.currentType == "win" and "W" or data.currentType == "loss" and "L" or "D")
    CreateStatCard(parent, "Current Streak", streakText, nil, PAD, cardY, cardW2)
    CreateStatCard(parent, "Longest Win Streak", tostring(data.longestWin), nil, PAD + cardSpacing, cardY, cardW2)
    CreateStatCard(parent, "Longest Loss Streak", tostring(data.longestLoss), nil, PAD + cardSpacing * 2, cardY, cardW2)
    CreateStatCard(parent, "Total Matches", tostring(data.totalMatches), nil, PAD + cardSpacing * 3, cardY, cardW2)

    -- Second row: milestones
    local row2Y = cardY - CARD_H - 10
    local winPct = data.totalMatches > 0 and math.floor(data.totalWins / data.totalMatches * 100) or 0
    CreateStatCard(parent, "Total Wins", tostring(data.totalWins), winPct .. "% win rate", PAD, row2Y, cardW2)
    CreateStatCard(parent, "Total Losses", tostring(data.totalLosses), nil, PAD + cardSpacing, row2Y, cardW2)

    local firstStr = data.firstDate > 0 and date("%m/%d/%y", data.firstDate) or "—"
    CreateStatCard(parent, "First Match", firstStr, nil, PAD + cardSpacing * 2, row2Y, cardW2)

    -- Comeback stat
    local comeback = ComputeComebackStat()
    local comebackText = comeback and (comeback.pct .. "%") or "—"
    local comebackSub = comeback and (comeback.wins .. "W / " .. comeback.total .. " after 3+ losses") or "Need more data"
    CreateStatCard(parent, "Comeback Rate", comebackText, comebackSub, PAD + cardSpacing * 3, row2Y, cardW2)

    return row2Y - CARD_H - 10 - SECTION_GAP
end

-- 18. Map Duration Analysis
local function RenderMapDurations(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Average Duration by Map", yOffset)
    local data = ComputeMapDurations()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        table.insert(chartData, {
            label = d.name, value = d.avg,
            rightLabel = FormatDuration(d.avg) .. " (" .. d.count .. " games)",
        })
    end
    local endY = DrawHorizontalBarChart(parent, chartData, PAD, yOffset - 5, CONTENT_W - PAD * 2, { labelWidth = 140, barHeight = 16, spacing = 3 })
    return endY - SECTION_GAP
end

-- 19. Session Analysis
local function RenderSessionAnalysis(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Session Analysis", yOffset)
    local data = ComputeSessionAnalysis()
    if not data then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local cardY = yOffset - 5
    local cardSpacing = (CONTENT_W - PAD * 2) / 3
    local cardW2 = cardSpacing - 10

    CreateStatCard(parent, "Total Sessions", tostring(data.sessionCount), nil, PAD, cardY, cardW2)
    CreateStatCard(parent, "Avg Session Length", FormatDuration(data.avgLength), nil, PAD + cardSpacing, cardY, cardW2)
    CreateStatCard(parent, "Avg Matches/Session", data.avgMatches, nil, PAD + cardSpacing * 2, cardY, cardW2)

    return cardY - CARD_H - 10 - SECTION_GAP
end

-- 20. Win Rate by Match Number in Session
local function RenderWinRateByMatchNum(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Win Rate by Match # in Session", yOffset)
    local data = ComputeWinRateByMatchInSession()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local chartData = {}
    for _, d in ipairs(data) do
        table.insert(chartData, {
            label = "#" .. d.matchNum,
            value = d.pct,
            topLabel = d.pct .. "% (" .. d.total .. ")",
        })
    end
    DrawVerticalBarChart(parent, chartData, PAD + 5, yOffset - 5, CONTENT_W - PAD * 2 - 10, 120, {})

    -- Explanatory note
    local noteFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteFS:SetFont(FONT, 9, "")
    noteFS:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_W - 220, yOffset - 5)
    noteFS:SetTextColor(0.45, 0.45, 0.45)
    noteFS:SetText("Sessions split by 30min gaps")

    return yOffset - 155 - SECTION_GAP
end

-- 21. Head-to-Head Breakdown
local function RenderHeadToHead(parent, yOffset)
    yOffset = CreateSectionHeader(parent, "Head-to-Head: Top 5 Opponents", yOffset)
    local data = ComputeHeadToHead()
    if #data == 0 then return CreateNoDataLabel(parent, yOffset) - SECTION_GAP end

    local cardW2 = CONTENT_W - PAD * 2
    local cardH2 = 60
    local ar, ag, ab = AccentRGB()

    for i, d in ipairs(data) do
        local cy = yOffset - 5 - (i - 1) * (cardH2 + 8)

        local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card:SetSize(cardW2, cardH2)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, cy)
        WG.ApplyModernStyle(card)

        -- Rank + Name
        local nameFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameFS:SetFont(FONT, 13, "")
        nameFS:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
        nameFS:SetTextColor(0.95, 0.95, 0.95)
        nameFS:SetText("#" .. i .. "  " .. d.name)

        -- W-L record
        local wr, wg, wb = WinRGB()
        local lr, lg, lb = LossRGB()
        local wlFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        wlFS:SetFont(FONT, 11, "")
        wlFS:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -28)
        local winPct = d.total > 0 and math.floor(d.wins / d.total * 100) or 0
        wlFS:SetTextColor(0.7, 0.7, 0.7)
        wlFS:SetText(d.wins .. "W - " .. d.losses .. "L  (" .. winPct .. "% WR)")

        -- Avg damage
        local dmgFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dmgFS:SetFont(FONT, 10, "")
        dmgFS:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -44)
        dmgFS:SetTextColor(0.5, 0.5, 0.5)
        dmgFS:SetText("Avg Dmg: " .. FormatNumber(d.avgDmg) .. "  |  Avg Heal: " .. FormatNumber(d.avgHeal))

        -- Favorite map (right side)
        local mapFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mapFS:SetFont(FONT, 10, "")
        mapFS:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -8)
        mapFS:SetTextColor(0.5, 0.5, 0.5)
        mapFS:SetText(d.favMap)

        -- Total games + last played (right side)
        local infoFS = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        infoFS:SetFont(FONT, 9, "")
        infoFS:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -24)
        infoFS:SetTextColor(0.4, 0.4, 0.4)
        local lastStr = d.lastDate > 0 and date("%m/%d/%y", d.lastDate) or ""
        infoFS:SetText(d.total .. " games  |  " .. lastStr)
    end

    local totalH = #data * (cardH2 + 8)
    return yOffset - 5 - totalH - SECTION_GAP
end

-- ---------- MAIN FRAME CREATION ----------

local function CreateAdvancedFrame()
    if advFrame then return advFrame end

    local f = CreateFrame("Frame", "WG_AdvancedStatsFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    WG.ApplyModernStyle(f)
    if WG.ApplyUIScale then WG.ApplyUIScale(f) end

    -- Shared chrome (accent stripe + title + close). Standardizes this frame's title
    -- color (was always accent-colored via AccentRGB(), which for the Alliance theme
    -- differs from titleColor) and close button (was a 60x22 "Close" text button, the
    -- only window in the addon that didn't use the small "X" glyph) onto the same
    -- convention every other window now uses.
    local chrome = WG.CreateWindowChrome(f, { title = "Advanced Stats" })

    -- Group tab strip (Overview / Performance / Opponents / Trends) replaces the old
    -- single continuously-scrolled 21-section wall.
    local tabStrip = WG.CreateTabStrip(f, {
        { key = "overview",    label = "Overview" },
        { key = "performance", label = "Performance" },
        { key = "opponents",   label = "Opponents" },
        { key = "trends",      label = "Trends" },
    }, {
        spacing = 20,
        onSelect = function(key)
            activeGroup = key
            RefreshAdvancedStats()
        end,
    })
    tabStrip:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -32)
    advTabStrip = tabStrip

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "WG_AdvancedScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -58)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)
    WG.ApplyModernStyle(scrollFrame)
    WG.StyleScrollBar(scrollFrame)

    -- Scroll content
    scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(CONTENT_W, 2400)
    scrollFrame:SetScrollChild(scrollContent)

    f:Hide()
    advFrame = f
    return f
end

-- ---------- REFRESH ----------

-- Sections grouped under the 4-tab strip; each group is rendered independently instead
-- of always rebuilding all 21 sections on every Show()/tab switch.
local SECTION_GROUPS = {
    overview = {
        RenderStreaksMilestones, RenderPersonalPerformance, RenderPeakRecords, RenderWinRateByMatchNum,
    },
    performance = {
        RenderModeBreakdown, RenderKDRPerMode, RenderEfficiency,
        RenderMapPerformance, RenderMapDurations, RenderDurationAnalysis,
    },
    opponents = {
        RenderClassMatchups, RenderNemesisRival, RenderMostPlayed, RenderHeadToHead,
        RenderClassCombos, RenderOpponentClassDist, RenderNewVsRepeat,
    },
    trends = {
        RenderTimeTrends, RenderSessionHistory, RenderActivityPatterns, RenderSessionAnalysis,
    },
}

function RefreshAdvancedStats()
    if not advFrame or not scrollContent then return end

    -- Remove all old content from scrollContent
    local children = { scrollContent:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    local regions = { scrollContent:GetRegions() }
    for _, region in ipairs(regions) do
        region:Hide()
        region:SetParent(nil)
    end

    local yOffset = -10

    -- Render only the active group's sections (was all 21, always, on every refresh)
    for _, renderFn in ipairs(SECTION_GROUPS[activeGroup] or SECTION_GROUPS.overview) do
        yOffset = renderFn(scrollContent, yOffset)
    end

    -- Set content height for scrolling
    local totalHeight = math.abs(yOffset) + 20
    scrollContent:SetSize(CONTENT_W, math.max(totalHeight, FRAME_H - 45))
end

-- ---------- PUBLIC API ----------

function WG.ToggleAdvancedStats()
    local f = CreateAdvancedFrame()
    if f:IsShown() then
        f:Hide()
        return
    end
    if WG.CloseSecondaryWindows then WG.CloseSecondaryWindows("WG_AdvancedStatsFrame") end
    f:Show()
    f:Raise()
    RefreshAdvancedStats()
end

-- Live re-theming: this panel previously had no WG.OnThemeChanged handler at all, so a
-- theme switch while it was open left every chart color/gray label stale until the next
-- close+reopen. WG.OnThemeChanged is a single global slot (not a registration list), and
-- tracker.lua already sets it — chain to whatever was there instead of overwriting it.
local previousOnThemeChanged = WG.OnThemeChanged
WG.OnThemeChanged = function()
    if previousOnThemeChanged then previousOnThemeChanged() end
    if advFrame and advFrame:IsShown() then RefreshAdvancedStats() end
end
