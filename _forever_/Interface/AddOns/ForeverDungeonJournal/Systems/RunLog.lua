-- Run Log: records every dungeon run of the character on its own.
--   * Every mob killed (trash and bosses) and the XP each one gave.
--   * Need rolls: the items this character pressed Need on, won or lost.
--   * Speed: from the first trash kill to the last boss kill.
--   * Deaths, and how much of the dungeon's trash was killed.
-- A run is one copy of a dungeon (its instance ID, read from the creatures'
-- GUIDs). Leaving and coming back (a corpse run after releasing, or a trip
-- out to a vendor) carries on the same run; a reset dungeon starts a new one.
-- The page that shows the runs is Systems/RunLogUI.lua.
--
-- Not the combat log: WoW Forever closes COMBAT_LOG_EVENT_* to addons. Kills
-- come from PARTY_KILL / UNIT_DIED (GUIDs), the hostile-death and XP chat
-- lines (names), ENCOUNTER_END, and corpses seen on nameplates. XP is the
-- change of UnitXP, matched to the kill it came with. Anything the client
-- hands over as a secret value is skipped.
local FDJ = _G.ForeverDungeonJournal_NS
if not FDJ then return end

local MAX_RUNS = 150
-- Dungeons whose bosses all act as rares on the tracker (testing only; empty).
FDJ.RUNLOG_TEST_RARES = {}
local RESUME_OPEN = 90 * 60      -- back inside within this time: same run (unfinished)
local RESUME_DONE = 20 * 60      -- same, once the final boss is dead
local MERGE_WINDOW = 3           -- seconds: two reports of one death
local XP_WINDOW = 4              -- seconds: XP given for a kill

local function Plain(v)
    if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
    return v
end

local function Now() return (GetServerTime and GetServerTime()) or time() end
local function Clock() return GetTime and GetTime() or 0 end

local function Say(text) print("|cffd8a83cDungeonJournal:|r " .. text) end

local function L(key, ...)
    if FDJ.L then return FDJ.L(key, ...) end
    return key
end

-- ------------------------------------------------------------ storage
local function Store()
    ForeverDungeonJournalCharacterDB = ForeverDungeonJournalCharacterDB or {}
    local db = ForeverDungeonJournalCharacterDB
    if type(db.runLog) ~= "table" then db.runLog = {} end
    local log = db.runLog
    if type(log.runs) ~= "table" then log.runs = {} end
    log.nextID = tonumber(log.nextID) or 1
    return log
end

local function Account()
    ForeverDungeonJournalDB = ForeverDungeonJournalDB or {}
    local db = ForeverDungeonJournalDB
    if type(db.runLogNames) ~= "table" then db.runLogNames = {} end         -- npcID -> name
    if type(db.runLogTrashTotal) ~= "table" then db.runLogTrashTotal = {} end -- dungeon -> trash count
    if type(db.runLogBossAliases) ~= "table" then db.runLogBossAliases = {} end -- boss npcID -> { lower name = true }
    return db
end

-- ------------------------------------------------------------ helpers
-- Creature-0-server-map-zoneUID-npcID-spawnUID: zoneUID is the instance copy.
local function ParseGUID(guid)
    guid = Plain(guid)
    if type(guid) ~= "string" then return nil end
    local kind, _, server, map, zone, npc, spawn = strsplit("-", guid)
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    npc = tonumber(npc)
    if not npc then return nil end
    return npc, tostring(server) .. ":" .. tostring(zone), tonumber(map), npc .. ":" .. tostring(spawn)
end

local function ItemIDOf(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

local function ItemCount(id)
    if not id then return 0 end
    local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not fn then return 0 end
    local ok, n = pcall(fn, id, true)
    n = ok and Plain(n)
    return type(n) == "number" and n or 0
end

local function Lower(s)
    s = Plain(s)
    if type(s) ~= "string" or s == "" then return nil end
    return (s:lower():gsub("\226\128\153", "'"))
end

-- A Blizzard format string ("%s dies, you gain %d experience.") as a Lua
-- pattern. Captures come back in argument order (some locales use %2$s).
local function MakePattern(fmt, anchorEnd)
    if type(fmt) ~= "string" or fmt == "" then return nil end
    local out, order, i = {}, {}, 1
    while i <= #fmt do
        local c = fmt:sub(i, i)
        if c == "%" then
            local pos, conv = fmt:match("^%%(%d)%$([sd])", i)
            local skip = 4
            if not conv then conv = fmt:match("^%%([sd])", i); skip = 2 end
            if conv then
                order[#order + 1] = tonumber(pos) or (#order + 1)
                out[#out + 1] = conv == "d" and "([%d%.,]+)" or "(.-)"
                i = i + skip
            elseif fmt:sub(i + 1, i + 1) == "%" then
                out[#out + 1] = "%%"
                i = i + 2
            else
                out[#out + 1] = "%%"
                i = i + 1
            end
        elseif c:find("[%(%)%.%+%-%*%?%[%]%^%$]") then
            out[#out + 1] = "%" .. c
            i = i + 1
        else
            out[#out + 1] = c
            i = i + 1
        end
    end
    return { pattern = "^" .. table.concat(out) .. (anchorEnd and "$" or ""), order = order }
end

local function Match(p, text)
    if not p or type(text) ~= "string" then return nil end
    local caps = { text:match(p.pattern) }
    if #caps == 0 then return nil end
    local args = {}
    for k, argIndex in ipairs(p.order) do args[argIndex] = caps[k] end
    return args
end

local function Number(s)
    if type(s) ~= "string" then return tonumber(s) end
    return tonumber((s:gsub("[^%d]", "")))
end

local patterns
local function Patterns()
    if patterns then return patterns end
    patterns = {
        xp = MakePattern(_G.COMBATLOG_XPGAIN_FIRSTPERSON, false),
        dies = MakePattern(_G.UNITDIESOTHER, true),
        slain = MakePattern(_G.SELFKILLOTHER, true),
        youWon = MakePattern(_G.LOOT_ROLL_YOU_WON, true),
        won = MakePattern(_G.LOOT_ROLL_WON, true),
        allPassed = MakePattern(_G.LOOT_ROLL_ALL_PASSED, true),
        needSelf = MakePattern(_G.LOOT_ROLL_NEED_SELF, true),
        lootOther = MakePattern(_G.LOOT_ITEM, true),
        greedSelf = MakePattern(_G.LOOT_ROLL_GREED_SELF, true),
        needOther = MakePattern(_G.LOOT_ROLL_NEED, true),
        greedOther = MakePattern(_G.LOOT_ROLL_GREED, true),
        rolledNeed = MakePattern(_G.LOOT_ROLL_ROLLED_NEED, true),
        rolledGreed = MakePattern(_G.LOOT_ROLL_ROLLED_GREED, true),
        rolledNeedBonus = _G.LOOT_ROLL_ROLLED_NEED_ROLE_BONUS and MakePattern(_G.LOOT_ROLL_ROLLED_NEED_ROLE_BONUS, true) or nil,
        lootSelf = MakePattern(_G.LOOT_ITEM_SELF, true),
        reset = MakePattern(_G.INSTANCE_RESET_SUCCESS or "%s has been reset.", true),
    }
    return patterns
end

-- ------------------------------------------------------------ dungeon data
local bossCache = {}
local function Bosses(dungeon)
    if not dungeon then return nil end
    local c = bossCache[dungeon]
    if c then return c end
    c = { byNpc = {}, byName = {}, finalNpc = nil, finalNames = {} }
    local d = FDJ.DB and FDJ.DB[dungeon]
    for _, b in ipairs((d and d.bosses) or {}) do
        if type(b) == "table" and not b.trash and not b.recipeTab and type(b.name) == "string" then
            if b.npcID then c.byNpc[b.npcID] = b end
            local names = { b.name }
            if FDJ.LocalizeBossName then
                local ok, loc = pcall(FDJ.LocalizeBossName, b.name)
                if ok and type(loc) == "string" then names[#names + 1] = loc end
            end
            for _, alias in ipairs(b.aliases or {}) do names[#names + 1] = alias end
            -- bossnames: its name in the client's language, learned in the
            -- game (units seen, the Encounter Journal). Kills told by name
            -- only (the boss kill event, "dies" lines) match it too.
            if b.npcID then
                local acc = Account()
                if type(acc.runLogNames[b.npcID]) == "string" then names[#names + 1] = acc.runLogNames[b.npcID] end
                for alias in pairs(acc.runLogBossAliases[b.npcID] or {}) do names[#names + 1] = alias end
            end
            for _, n in ipairs(names) do
                local lower = Lower(n)
                if lower and not c.byName[lower] then c.byName[lower] = b end
            end
        end
    end
    if FDJ.FinalBossOf then
        local ok, id, names = pcall(FDJ.FinalBossOf, dungeon)
        if ok then
            c.finalNpc = id
            c.finalNames = type(names) == "table" and names or {}
        end
    end
    -- No final boss known: the last real boss of the journal page.
    if not c.finalNpc and not next(c.finalNames) then
        local last
        for _, b in ipairs((d and d.bosses) or {}) do
            if type(b) == "table" and not b.trash and not b.rare and not b.recipeTab and type(b.name) == "string" then last = b end
        end
        if last then
            c.finalNpc = last.npcID
            c.finalNames[Lower(last.name)] = true
        end
    end
    bossCache[dungeon] = c
    return c
end

local function BossFor(dungeon, npc, name)
    local c = Bosses(dungeon)
    if not c then return nil end
    if npc and c.byNpc[npc] then return c.byNpc[npc] end
    local lower = Lower(name)
    return lower and c.byName[lower] or nil
end

-- ringoflaw (2.0.4): bosses that are one fight of which only one shows up
-- (the Ring of Law's challengers, data: fightGroup = "Ring of Law"). The
-- fight's own name and each member's name give the fight's name.
local function FightGroup(dungeon, name)
    local lower = Lower(name)
    local d = lower and dungeon and FDJ.DB and FDJ.DB[dungeon]
    for _, b in ipairs((d and d.bosses) or {}) do
        if type(b) == "table" and type(b.fightGroup) == "string" then
            if Lower(b.fightGroup) == lower or Lower(b.name) == lower then return b.fightGroup, (Lower(b.name) == lower) and b or nil end
        end
    end
    return nil
end

local function IsFinal(dungeon, npc, name, boss)
    local c = Bosses(dungeon)
    if not c then return false end
    if npc and c.finalNpc and npc == c.finalNpc then return true end
    if boss and boss.npcID and c.finalNpc and boss.npcID == c.finalNpc then return true end
    local lower = Lower(name)
    if lower and c.finalNames[lower] then return true end
    if boss then
        local bl = Lower(boss.name)
        if bl and c.finalNames[bl] then return true end
    end
    return false
end

local function NameOfNpc(npc)
    if not npc then return nil end
    return Account().runLogNames[npc]
end

local FixBossKillsAll -- below: kills renamed once a boss's local name is known

-- The journal's boss NPC IDs (all dungeons).
local bossNpcs
local function IsBossNpc(npc)
    if not bossNpcs then
        bossNpcs = {}
        for _, d in pairs(FDJ.DB or {}) do
            for _, b in ipairs((type(d) == "table" and d.bosses) or {}) do
                if type(b) == "table" and type(b.npcID) == "number" and not b.trash then bossNpcs[b.npcID] = true end
            end
        end
    end
    return npc ~= nil and bossNpcs[npc] == true
end

-- Another name a boss goes by (its name in the client's language). True if new.
local function AddBossAlias(npc, name)
    local lower = Lower(name)
    if not npc or not lower or not IsBossNpc(npc) then return false end
    local aliases = Account().runLogBossAliases
    aliases[npc] = aliases[npc] or {}
    local added = false
    if not aliases[npc][lower] then aliases[npc][lower] = true added = true end
    for _, c in pairs(bossCache) do
        local b = c.byNpc[npc]
        if b and not c.byName[lower] then c.byName[lower] = b added = true end
    end
    return added
end

local function LearnName(npc, name)
    name = Plain(name)
    if npc and type(name) == "string" and name ~= "" and name ~= (UNKNOWNOBJECT or "Unknown") then
        Account().runLogNames[npc] = name
        if AddBossAlias(npc, name) and FixBossKillsAll then FixBossKillsAll() end
    end
end

-- bossnames: the game's own boss names, in the client's language, from the
-- Encounter Journal. A journal creature is matched to the addon's boss by its
-- model (FDJ.STATIC_DISPLAY_IDS), so it works in every language, also for
-- bosses with no translation in the addon and when Forever hides NPC IDs.
local journalScanned = false
local function LearnFromJournal(force)
    if journalScanned and not force then return false end
    journalScanned = true
    if type(EJ_GetInstanceByIndex) ~= "function" or type(EJ_SelectInstance) ~= "function"
        or type(EJ_GetEncounterInfoByIndex) ~= "function" or type(EJ_GetCreatureInfo) ~= "function" then return false end
    -- Don't move the journal the player is reading.
    if EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown() then journalScanned = false return false end
    local byDisplay, shared = {}, {}
    for npc, display in pairs(FDJ.STATIC_DISPLAY_IDS or {}) do
        if type(display) == "number" and IsBossNpc(npc) then
            if byDisplay[display] and byDisplay[display] ~= npc then shared[display] = true else byDisplay[display] = npc end
        end
    end
    for display in pairs(shared) do byDisplay[display] = nil end -- one model, two bosses: not used
    if not next(byDisplay) then return false end
    local prevTier
    if type(EJ_GetCurrentTier) == "function" then
        local ok, t = pcall(EJ_GetCurrentTier)
        if ok and type(t) == "number" then prevTier = t end
    end
    local tiers = { false }
    if type(EJ_GetNumTiers) == "function" and type(EJ_SelectTier) == "function" then
        local ok, n = pcall(EJ_GetNumTiers)
        if ok and type(n) == "number" and n > 0 then
            tiers = {}
            for t = 1, n do tiers[#tiers + 1] = t end
        end
    end
    local learned = false
    for _, tier in ipairs(tiers) do
        if tier then pcall(EJ_SelectTier, tier) end
        for _, raid in ipairs({ false, true }) do
            for i = 1, 200 do
                local ok, instanceID = pcall(EJ_GetInstanceByIndex, i, raid)
                if not ok or not instanceID then break end
                pcall(EJ_SelectInstance, instanceID)
                for e = 1, 40 do
                    local okE, encName, _, encID = pcall(EJ_GetEncounterInfoByIndex, e, instanceID)
                    if not okE or not encID then okE, encName, _, encID = pcall(EJ_GetEncounterInfoByIndex, e) end
                    if not okE or not encID then break end
                    for c = 1, 8 do
                        local okC, _, cName, _, display = pcall(EJ_GetCreatureInfo, c, encID)
                        if not okC or not cName then break end
                        local npc = byDisplay[display]
                        if npc then
                            if AddBossAlias(npc, cName) then learned = true end
                            if AddBossAlias(npc, encName) then learned = true end
                        end
                    end
                end
            end
        end
    end
    if prevTier and type(EJ_SelectTier) == "function" then pcall(EJ_SelectTier, prevTier) end
    if learned and FixBossKillsAll then FixBossKillsAll() end
    return learned
end
local journalTried = {}

-- ------------------------------------------------------------ where we are
local inside, insideMap, insideDungeon = false, nil, nil
local current            -- the run being recorded (inside the dungeon)
local unitEvidence = { guid = {}, name = {} } -- session-only creature eligibility
local recent = {}        -- kills of the last seconds (session only): merging
local session = {}       -- run.id -> { killed = {guidKey}, seen = {guidKey} } kept in memory too

local function InDungeon()
    if not IsInInstance then return false end
    local inInstance, kind = IsInInstance()
    if not Plain(inInstance) then return false end
    if kind ~= "party" and kind ~= "raid" then return false end
    local name, _, _, _, _, _, _, map = GetInstanceInfo()
    local dungeon
    if FDJ.CurrentDungeon then
        local ok, d = pcall(FDJ.CurrentDungeon)
        if ok then dungeon = d end
    end
    -- A remembered/default Scarlet choice is not evidence for this run.
    -- Keep a fresh tracker generic until the room/door or a kill identifies it.
    if tonumber(map) == 189 and FDJ.ResolveScarletWing then
        local ok, wing, _, certain = pcall(FDJ.ResolveScarletWing)
        if ok then dungeon = certain and wing or nil end
    end
    -- Both Spire routes share an entrance. Even a named room may be shared
    -- (Hall of Blackhand); only a wing-specific kill chooses the run's wing.
    if tonumber(map) == 229 then dungeon = nil end
    return true, tonumber(map), dungeon, Plain(name)
end

local function Changed()
    if FDJ.RunLogChanged then pcall(FDJ.RunLogChanged) end
end

local function RunSets(run)
    if type(run.seen) ~= "table" then run.seen = {} end
    if type(run.killedG) ~= "table" then run.killedG = {} end
end

local function TrashKilled(run)
    local n = 0
    for _, k in ipairs(run.kills or {}) do
        if not k.b and not k.wb and not k.p then n = n + 1 end
    end
    return n
end

local function TrashSeen(run)
    if run.seenN then return run.seenN end
    local n = 0
    for _ in pairs(run.seen or {}) do n = n + 1 end
    -- Kills known by name only (no GUID) were never in the seen list.
    for _, k in ipairs(run.kills or {}) do
        if not k.b and not k.g and not k.wb and not k.p then n = n + 1 end
    end
    return n
end

local function IsEmpty(run)
    return not run.startedAt and #(run.kills or {}) == 0 and (run.deaths or 0) == 0 and #(run.needs or {}) == 0
end

local function CloseRun(run)
    if not run or run.closed then return end
    run.closed = true
    -- 2.0.4: an unfinished run keeps its time: until it was ended, or the
    -- last time you were inside.
    if not run.completed and not run.endedAt then
        run.endedAt = (run.outside and run.outside.t) or (current == run and Now()) or run.lastSeen or Now()
    end
    run.seenN = TrashSeen(run)
    run.seen, run.killedG = nil, nil
    if run.outside and not run.outside.back then run.outside.open = nil end
    run.outside = nil
    if current == run then current = nil end
    local log = Store()
    if IsEmpty(run) then
        for i = #log.runs, 1, -1 do
            if log.runs[i] == run then table.remove(log.runs, i) break end
        end
    elseif run.completed and run.dungeon then
        -- A finished run teaches how much trash the dungeon has.
        local totals = Account().runLogTrashTotal
        local n = math.max(run.seenN or 0, TrashKilled(run))
        if n > (tonumber(totals[run.dungeon]) or 0) then totals[run.dungeon] = n end
    end
    Changed()
end

local function Trim(log)
    while #log.runs > MAX_RUNS do
        local removed = false
        for i = 1, #log.runs do
            if log.runs[i].closed then table.remove(log.runs, i) removed = true break end
        end
        if not removed then table.remove(log.runs, 1) end
    end
end

local function OpenRunOf(map)
    for _, run in ipairs(Store().runs) do
        if not run.closed and run.map == map then return run end
    end
end

local function AwaitingWing()
    return inside and FDJ.RunLogWingGroups and FDJ.RunLogWingGroups[insideMap]
        and not insideDungeon
end

local function EnsureRun()
    if AwaitingWing() then return nil end
    if current then return current end
    if not inside then return nil end
    local log = Store()
    local run = {
        id = log.nextID,
        map = insideMap,
        dungeon = insideDungeon,
        instanceName = select(4, InDungeon()),
        created = Now(),
        kills = {}, needs = {}, exits = {}, deathTimes = {},
        deaths = 0, otherXP = 0,
        seen = {}, killedG = {},
    }
    log.nextID = log.nextID + 1
    if FDJ.RunLogIsCapped and FDJ.RunLogIsCapped() then run.capped = true end
    table.insert(log.runs, run)
    Trim(log)
    current = run
    Changed()
    return run
end

-- The instance copy, from a creature's GUID. A different copy of the same
-- dungeon means it was reset: the old run ends, a new one starts.
local function CheckZone(zone, map)
    if not inside or not zone then return end
    if map and insideMap and map ~= insideMap then return end
    -- A run starts with the first kill, not with a mob merely seen.
    local run = current
    if not run then return end
    if not run.zone then
        run.zone = zone
    elseif run.zone ~= zone then
        -- Not back in that copy after all: its last trip out never ended.
        local last = run.exits and run.exits[#run.exits]
        if last and last.back and (Now() - last.back) < 600 then
            local since = false
            for _, k in ipairs(run.kills or {}) do
                if k.t >= last.back then since = true break end
            end
            if not since then last.back = nil end
        end
        CloseRun(run)
        recent = {}
        local fresh = EnsureRun()
        if fresh then fresh.zone = zone end
    end
end

-- ------------------------------------------------------------ kills
local pendingXP = {}   -- { clock, amount }: XP that came before its kill

-- A run is complete once every boss of the journal page is dead, not just
-- the last one (a skipped boss keeps it open). Rares and bosses that need a
-- quest or a summoning item to appear are optional. A dungeon without boss
-- data completes on its final boss.
local function AllBossesDown(run, kill)
    local d = run.dungeon and FDJ.DB and FDJ.DB[run.dungeon]
    local needed, known, group = {}, {}, {}
    for _, b in ipairs((d and d.bosses) or {}) do
        if type(b) == "table" and type(b.name) == "string" and not b.trash and not b.recipeTab then
            known[b.name] = true
            -- ringoflaw: one fight, whichever of its bosses shows up
            local key = type(b.fightGroup) == "string" and b.fightGroup or b.name
            if key ~= b.name then known[key] = true group[b.name] = key group[key] = key end
            if not b.rare and not b.spawnQuest and not b.summonItem and not b.optional then needed[key] = true end
        end
    end
    if not next(needed) then return kill.f and true or false end
    local unknown = {}
    for _, k in ipairs(run.kills or {}) do
        if k.b then
            local key = group[k.b] or k.b
            if needed[key] then needed[key] = nil
            elseif not known[k.b] then unknown[k.b] = true end
        end
    end
    if next(needed) == nil then return true end
    -- bossnames: boss kills under names the journal doesn't know yet (the
    -- client's language, no translation): as many of them as bosses still
    -- open means every boss is down.
    local left, extra = 0, 0
    for _ in pairs(needed) do left = left + 1 end
    for _ in pairs(unknown) do extra = extra + 1 end
    return extra >= left
end

local SetKillTimes
SetKillTimes = function(run, kill)
    if not run.firstKill then run.firstKill = kill.t end
    if not kill.b and not kill.wb and not kill.p and not run.firstTrash then run.firstTrash = kill.t end
    if kill.b and not kill.r then run.lastBoss = kill.t end
    if kill.b and not run.completed and AllBossesDown(run, kill) then
        run.completed = true
        run.finalKill = kill.t
        -- A moment later, once the boss's XP is counted.
        C_Timer.After(2, function()
            if FDJ.RunLogSummary then
                local ok, text = pcall(FDJ.RunLogSummary, run)
                if ok and text then Say(text) end
            end
        end)
    end
end

-- A boss fought together with others (killWith = { "Ruuzlu" }): its fight
-- is over, and the boss counted killed, only once all of them are dead.
-- The boss's own kill waits (wb) until then; the others' kills are part of
-- the fight (p), not trash.
local function IsPartner(boss, kill)
    -- each partner: a name, an NPC ID, or { name, NPC ID } (either matches)
    for _, partner in ipairs(boss.killWith or {}) do
        for _, v in ipairs(type(partner) == "table" and partner or { partner }) do
            if (type(v) == "number" and kill.n == v)
                or (type(v) == "string" and kill.m and Lower(kill.m) == Lower(v)) then
                return true
            end
        end
    end
    return false
end
local function PartnersDead(run, boss)
    for _, partner in ipairs(boss.killWith or {}) do
        local dead = false
        for _, k in ipairs(run.kills or {}) do
            if IsPartner({ killWith = { partner } }, k) then dead = true break end
        end
        if not dead then return false end
    end
    return true
end

-- killedbefore (2.0.4): a boss that only shows up once another boss is dead
-- (Sneed comes out of his Shredder; data: killedBefore = { name, NPC ID }).
-- Its kill counts the other one too: with no XP for it and its name hidden,
-- that death was only an unnamed kill. That kill (the last unnamed one, at
-- most two minutes earlier) becomes the boss; else the boss is added.
local KILLED_BEFORE_WINDOW = 120
local function CreditOther(run, name, npc, kill)
    if type(name) ~= "string" then return end
    for _, k in ipairs(run.kills or {}) do
        if k.b == name or k.wb == name then return end
    end
    local at, hidden = nil, nil
    for i = #run.kills, 1, -1 do
        local k = run.kills[i]
        if k == kill then
            at = i
        elseif not hidden and not k.b and not k.wb and not k.p and not k.m and k.a
            and (not kill.t or not k.t or kill.t - k.t <= KILLED_BEFORE_WINDOW) then
            hidden = k
        end
        if hidden then break end
    end
    -- c: counted through another boss, not by its own death
    if hidden then
        hidden.b, hidden.m = name, name
        hidden.n = hidden.n or npc
        hidden.r = nil
        hidden.c = 1
        if SetKillTimes then SetKillTimes(run, hidden) end
        return
    end
    local credited = { t = kill.t, n = npc, m = name, b = name, c = 1 }
    table.insert(run.kills, at or (#run.kills + 1), credited)
    if SetKillTimes then SetKillTimes(run, credited) end
end
local function CreditKilledBefore(run, boss, kill)
    local before = type(boss) == "table" and boss.killedBefore
    if type(before) ~= "table" then return end
    CreditOther(run, before[1], tonumber(before[2]), kill)
end

-- ruuzlu (2.0.4): a boss's partner that is a boss of its own (Ruuzlu, with
-- Chief Ukorz Sandscalp). The fight's boss event says the fight is over:
-- the boss is killed, and so is a partner whose own death went unnamed (no
-- XP at a high level).
local function EventEndsFight(run, kill, boss)
    if type(boss) ~= "table" or type(boss.killWith) ~= "table" then return end
    local dungeon = run.dungeon or insideDungeon
    if kill.wb == boss.name or not kill.b then
        kill.b, kill.wb = boss.name, nil
        if not boss.rare and IsFinal(dungeon, kill.n, kill.m, boss) then kill.f = 1 end
    end
    for _, partner in ipairs(boss.killWith) do
        local name, npc
        for _, v in ipairs(type(partner) == "table" and partner or { partner }) do
            if type(v) == "string" then name = v elseif type(v) == "number" then npc = v end
        end
        local other = BossFor(dungeon, npc, name)
        if other and other ~= boss then CreditOther(run, other.name, other.npcID or npc, kill) end
    end
end

-- A partner died: a boss waiting for it (its own death came first) is
-- killed now, if this was the last one. mark: the kill is part of that
-- fight, not trash (a partner with no page of its own).
local function PartnerDied(run, kill, dungeon, mark)
    local d = dungeon and FDJ.DB and FDJ.DB[dungeon]
    for _, b in ipairs((d and d.bosses) or {}) do
        if type(b) == "table" and type(b.killWith) == "table" and IsPartner(b, kill) then
            if mark then kill.p = 1 end
            for _, k in ipairs(run.kills or {}) do
                if k.wb == b.name and k ~= kill then
                    -- (this kill is not in the list yet: count it as dead)
                    local others = {}
                    for _, partner in ipairs(b.killWith) do
                        if not IsPartner({ killWith = { partner } }, kill) then others[#others + 1] = partner end
                    end
                    if PartnersDead(run, { killWith = others }) then
                        k.wb = nil
                        k.b = b.name
                        k.t = kill.t or k.t -- the fight ended with this death
                        if not b.rare and IsFinal(dungeon, k.n, k.m, b) then k.f = 1 end
                        if SetKillTimes then SetKillTimes(run, k) end
                    end
                end
            end
            return true
        end
    end
    return false
end

local function ClassifyKill(run, kill)
    local dungeon = run.dungeon or insideDungeon
    local boss = BossFor(dungeon, kill.n, kill.m)
    if boss then
        -- ruuzlu: already counted through its partner's fight event: this
        -- death is part of that fight
        for _, k in ipairs(run.kills or {}) do
            if k ~= kill and k.c and k.b == boss.name then kill.p = 1 return end
        end
        if type(boss.killWith) == "table" and not PartnersDead(run, boss) then
            kill.wb = boss.name
            return
        end
        kill.b = boss.name
        kill.wb = nil
        kill.r = boss.rare and 1 or nil
        if not kill.r and IsFinal(dungeon, kill.n, kill.m, boss) then kill.f = 1 end
        CreditKilledBefore(run, boss, kill)
        -- ruuzlu: a boss that is also another boss's partner
        PartnerDied(run, kill, dungeon, false)
        return
    end
    -- One of a boss's partners: part of that fight; if the boss is already
    -- dead and this was the last one, the fight is over now.
    PartnerDied(run, kill, dungeon, true)
end

-- bossnames: a run's boss kills recorded under another name (the client's
-- language) get the journal's name once that name is known; the run then
-- completes if every boss is down.
local function FixBossKills(run)
    local dungeon = type(run) == "table" and run.dungeon
    if not dungeon or type(run.kills) ~= "table" then return false end
    local changed, lastBoss = false, nil
    for _, k in ipairs(run.kills) do
        if k.b then
            local boss = BossFor(dungeon, k.n, k.b) or (k.m and BossFor(dungeon, k.n, k.m))
            if boss and boss.name ~= k.b then
                k.b = boss.name
                k.r = boss.rare and 1 or nil
                if not k.r and IsFinal(dungeon, k.n, k.m or boss.name, boss) then k.f = 1 end
                changed = true
            end
            if not k.r then lastBoss = k end
        elseif k.p and not k.wb and k.m and BossFor(dungeon, k.n, k.m) then
            -- ruuzlu: a partner that has its own page now
            local boss = BossFor(dungeon, k.n, k.m)
            local dup = false
            for _, o in ipairs(run.kills) do if o ~= k and o.b == boss.name then dup = true break end end
            if not dup then
                k.b, k.p = boss.name, nil
                k.r = boss.rare and 1 or nil
                changed = true
            end
        elseif not k.wb and not k.p and k.m then
            -- A boss's death counted as trash (its name wasn't known then).
            local boss = BossFor(dungeon, k.n, k.m)
            if boss and type(boss.killWith) ~= "table" then
                k.b = boss.name
                k.r = boss.rare and 1 or nil
                if not k.r and IsFinal(dungeon, k.n, k.m, boss) then k.f = 1 end
                changed = true
                if not k.r then lastBoss = k end
            end
        end
    end
    if not run.completed and lastBoss and AllBossesDown(run, lastBoss) then
        run.completed = true
        run.finalKill = run.finalKill or lastBoss.t
        changed = true
    end
    return changed
end
FixBossKillsAll = function()
    local any = false
    for _, run in ipairs(Store().runs) do
        if FixBossKills(run) then any = true end
    end
    if any then Changed() end
    return any
end

-- encounterids (2.0.3): ENCOUNTER_END's encounter ID is the same number on
-- every client language (Data/RunLogEncounters.lua). The kill is told under the
-- journal's name, so it counts whatever the client calls the boss; the boss
-- learns that local name, so its "dies" lines and earlier kills match too. An
-- instance the addon didn't recognise is named by its boss.
function FDJ.RunLogEncounterName(id, name)
    local hit = tonumber(id) and FDJ.RUNLOG_ENCOUNTERS and FDJ.RUNLOG_ENCOUNTERS[tonumber(id)]
    if type(hit) ~= "table" then return name end
    local dungeon, bossName = hit[1], hit[2]
    local d = FDJ.DB and FDJ.DB[dungeon]
    if not d then return name end
    local wings = FDJ.RunLogWingGroups and insideMap and FDJ.RunLogWingGroups[insideMap]
    if inside and not insideDungeon and not wings then
        insideDungeon = dungeon
        if current and not current.dungeon then current.dungeon = dungeon end
    end
    if type(name) == "string" and name ~= "" and Lower(name) ~= Lower(bossName) then
        for _, b in ipairs(d.bosses or {}) do
            if type(b) == "table" and b.name == bossName then
                if b.npcID and AddBossAlias(b.npcID, name) and FixBossKillsAll then FixBossKillsAll() end
                break
            end
        end
    end
    return bossName
end

-- resetsplit (2.0.3): a boss that died before you last left the dungeon dies
-- again after you came back: the dungeon was reset (by the group leader, whose
-- reset message the others never get, or before this version). The old run
-- ends there; everything since you came back in starts the new run.
function FDJ.RunLogSplitAfterReset(run, boss, name)
    if not run or run.closed or type(run.exits) ~= "table" then return nil end
    local last = run.exits[#run.exits]
    if not (last and last.t and last.back) then return nil end
    local dungeon = run.dungeon or insideDungeon
    local lower = Lower(boss and boss.name or name)
    local again = false
    for _, k in ipairs(run.kills or {}) do
        if k.t < last.t and (k.b or k.m) then
            if (lower and (Lower(k.b) == lower or Lower(k.m) == lower))
                or (boss and BossFor(dungeon, k.n, k.b or k.m) == boss) then
                again = true
                break
            end
        end
    end
    if not again then return nil end
    local moved = {}
    for i = #run.kills, 1, -1 do
        if run.kills[i].t >= last.back then table.insert(moved, 1, table.remove(run.kills, i)) end
    end
    run.resetAt = run.resetAt or last.back
    CloseRun(run)
    local fresh = EnsureRun()
    if not fresh then return nil end
    for _, k in ipairs(moved) do
        table.insert(fresh.kills, k)
        SetKillTimes(fresh, k)
    end
    return fresh
end

local function TakePendingXP(kill)
    local now = Clock()
    for i = #pendingXP, 1, -1 do
        local p = pendingXP[i]
        if now - p[1] <= 2 then
            kill.x = (kill.x or 0) + p[2]
            table.remove(pendingXP, i)
        end
    end
end

-- A wing-specific mob or boss is stronger evidence than a generic instance
-- name. Ambiguous/shared names never choose a wing.
local function WingFor(npc, name)
    local group = FDJ.RunLogWingGroups and FDJ.RunLogWingGroups[insideMap]
    local found
    for _, wing in ipairs(group or {}) do
        local matched = BossFor(wing, npc, name) ~= nil
        for id, english in pairs((FDJ.RunLogWingTrash or {})[wing] or {}) do
            if npc == id or (Lower(name) and (Lower(name) == Lower(english)
                or Lower(name) == Lower(NameOfNpc(id)))) then matched = true break end
        end
        if matched then
            if found and found ~= wing then return nil end
            found = wing
        end
    end
    return found
end

local function ApplyWing(wing, confirmed)
    if not wing then return end
    -- A positive kill in another wing begins its own log, even when both
    -- wings share a physical instance. Merely walking through a room does not.
    -- Do not carry a generic run's entrance timer from older addon versions
    -- into a newly identified wing. Keep that old log as a separate record.
    if current and not current.dungeon and FDJ.RunLogWingGroups[insideMap] then
        CloseRun(current)
        recent = {}
    end
    if current and current.wingConfirmed and current.dungeon ~= wing then
        if not confirmed then return end
        CloseRun(current)
        recent = {}
    end
    insideDungeon = wing
    if current then
        if current.dungeon ~= wing then
            current.dungeon = wing
            current.firstKill, current.firstTrash, current.lastBoss = nil, nil, nil
            current.completed, current.finalKill = nil, nil
            for _, k in ipairs(current.kills) do
                k.b, k.wb, k.p, k.r, k.f = nil, nil, nil, nil, nil
                ClassifyKill(current, k)
            end
            for _, k in ipairs(current.kills) do SetKillTimes(current, k) end
        end
        if confirmed then current.wingConfirmed = true end
    end
end

local function ExcludedType(ctype)
    if type(ctype) ~= "string" then return false end
    -- UnitCreatureType is localized; these are the client critter labels.
    local critters = { ["Critter"] = true, ["Kleintier"] = true, ["Bestiole"] = true,
        ["Alma"] = true, ["Animale"] = true, ["Bicho"] = true,
        ["Существо"] = true, ["小动物"] = true, ["小動物"] = true, ["동물"] = true }
    return critters[ctype] or ctype == _G.CRITTER or ctype == "Totem"
        or ctype == "Non-combat Pet" or ctype == "Wild Pet"
end

local function ObserveUnit(unit)
    if not inside or not UnitExists or not Plain(UnitExists(unit)) then return end
    local guid = Plain(UnitGUID(unit))
    local name = Plain(UnitName(unit))
    local ctype = Plain(UnitCreatureType(unit))
    local controlled = Plain(UnitPlayerControlled(unit))
    local hostile = Plain(UnitCanAttack("player", unit))
    local eligible
    if ExcludedType(ctype) or controlled then eligible = false
    elseif type(ctype) == "string" and hostile then eligible = true end
    if eligible == nil then return end
    if type(guid) == "string" then unitEvidence.guid[guid] = eligible end
    if Lower(name) then unitEvidence.name[Lower(name)] = eligible end
    local npc = ParseGUID(guid)
    if npc then LearnName(npc, name) end
end

local function ObserveTargets()
    -- Party/raid targets cover the first pull even with enemy nameplates off.
    ObserveUnit("target")
    ObserveUnit("mouseover")
    if IsInRaid and IsInRaid() then
        for i = 1, 40 do ObserveUnit("raid" .. i .. "target") end
    else
        for i = 1, 4 do ObserveUnit("party" .. i .. "target") end
    end
end

-- fightkill: inside Forever instances the creature type (and often the
-- GUID) is hidden, and an overlevelled or capped player gets no XP, so a
-- trash "X dies." / "You have slain X!" line carried no proof and no run
-- started until the first boss. A hostile death while the player or the
-- party is fighting (or just stopped) is a real kill. Common critter names
-- stay out: hitting a critter puts you in combat too.
local fight = { on = false, untilT = 0, critters = {
    ["rat"] = true, ["roach"] = true, ["cockroach"] = true, ["beetle"] = true,
    ["fire beetle"] = true, ["maggot"] = true, ["larva"] = true, ["snake"] = true,
    ["adder"] = true, ["frog"] = true, ["toad"] = true, ["squirrel"] = true,
    ["rabbit"] = true, ["hare"] = true, ["mouse"] = true, ["deer"] = true,
    ["fawn"] = true, ["sheep"] = true, ["chicken"] = true, ["cow"] = true,
    ["prairie dog"] = true, ["skunk"] = true, ["lava crab"] = true, ["crab"] = true,
    ["spider"] = true, ["scorpion"] = true, ["black rat"] = true, ["undercity cockroach"] = true,
    ["ratte"] = true, ["kakerlake"] = true, ["käfer"] = true, ["schlange"] = true,
    ["frosch"] = true, ["kröte"] = true, ["eichhörnchen"] = true, ["kaninchen"] = true,
    ["rat d'égout"] = true, ["cafard"] = true, ["scarabée"] = true, ["serpent"] = true,
} }

function FDJ.RunLogNoteFight(on)
    fight.on = on and true or false
    if not on then fight.untilT = Clock() + 3 end
end

function FDJ.RunLogInFight()
    if fight.on or Clock() <= fight.untilT then return true end
    if type(UnitAffectingCombat) ~= "function" then return false end
    local ok, v = pcall(UnitAffectingCombat, "player")
    if ok and Plain(v) then return true end
    for i = 1, 4 do
        ok, v = pcall(UnitAffectingCombat, "party" .. i)
        if ok and Plain(v) then return true end
    end
    return false
end

function FDJ.RunLogFightKill(name)
    local n = Lower(name)
    if not n or fight.critters[n] then return false end
    return FDJ.RunLogInFight()
end

-- What the game told us this session (for /dj tracker when nothing shows).
FDJ.RunLogSignals = { hidden = 0, plain = 0, xp = 0, boss = 0 }

local function EligibleKill(guid, npc, name, how)
    if how == "party" then return true end
    local evidence = guid and unitEvidence.guid[guid]
    if evidence == nil and Lower(name) then evidence = unitEvidence.name[Lower(name)] end
    if evidence == false then return false end
    if evidence == true then return true end
    if WingFor(npc, name) or BossFor((current and current.dungeon) or insideDungeon, npc, name) then return true end
    for id, english in pairs((FDJ.RunLogSharedTrash or {})[insideMap] or {}) do
        if npc == id or (Lower(name) and (Lower(name) == Lower(english)
            or Lower(name) == Lower(NameOfNpc(id)))) then return true end
    end
    -- fightkill: a death line during a fight is a real kill, even with no XP
    -- (overlevelled, level cap) and the mob's type hidden by the instance.
    if how == "death" and FDJ.RunLogFightKill(name) then return true end
    -- Positive XP is proof of a real kill. Unknown GUID-only reports out of
    -- combat cannot distinguish an unseen critter, so do not create a run.
    return how == "xp" or how == "boss"
end

local function OnPusillinGossip()
    if not inside or insideMap ~= 429 then return end
    -- "npc" is the actual gossip partner; a selected target is not proof.
    local npc = ParseGUID(Plain(UnitGUID("npc")))
    local name = Plain(UnitName("npc"))
    local boss = BossFor("Dire Maul: East", npc, name)
    if npc ~= 14354 and not (boss and boss.name == "Pusillin") then return end
    ApplyWing("Dire Maul: East", true)
    local run = EnsureRun()
    if not run then return end
    run.wingConfirmed = true
    if not run.startedAt and not run.firstKill then run.startedAt = Now() end
    Changed()
end

-- Adds a kill, or completes one already reported by another event.
-- guid: the GUID if known; name: the mob's name if known. how: which kind
-- of report this is ("guid" PARTY_KILL/UNIT_DIED/corpse, "xp" the XP chat
-- line, "death" the "<mob> dies." line, "boss" ENCOUNTER_END). One death is
-- told at most once by each kind, so three Risen Sentries dying together
-- stay three kills, while the four reports of one death stay one.
local function AddKill(guid, name, how)
    if not inside then return nil end
    how = how or "guid"
    guid, name = Plain(guid), Plain(name)
    local npc, zone, map, key = ParseGUID(guid)
    if map and insideMap and map ~= insideMap then return nil end
    if type(name) ~= "string" or name == "" then name = nil end
    name = name or NameOfNpc(npc)
    if not npc and not name and how ~= "party" then return nil end
    ObserveTargets()
    name = name or NameOfNpc(npc)
    if not EligibleKill(guid, npc, name, how) then return nil end
    -- Old corpses visible on entry must not start a fresh timer.
    if how == "corpse" and not current then return nil end
    if zone then CheckZone(zone, map) end
    local wing = WingFor(npc, name)
    if how == "corpse" and wing and current.dungeon ~= wing then return nil end
    ApplyWing(wing, true)
    if not EnsureRun() then return nil end
    if zone then CheckZone(zone, map) end
    local run = current
    if wing then run.wingConfirmed = true end
    RunSets(run)
    if npc and run.killedG[key] then return nil end
    local now = Clock()
    local dungeon = run.dungeon or insideDungeon
    local boss = BossFor(dungeon, npc, name)
    -- bossnames: a boss kill under a name the journal doesn't know: read the
    -- game's names from the Encounter Journal (once per name) and try again.
    if not boss and how == "boss" and Lower(name) and not journalTried[Lower(name)] then
        journalTried[Lower(name)] = true
        pcall(LearnFromJournal, true)
        boss = BossFor(dungeon, npc, name)
    end

    -- The same death, told by another event: complete that kill.
    for i = #recent, 1, -1 do
        local r = recent[i]
        if now - r.clock > MERGE_WINDOW then break end
        local k = r.kill
        local same = false
        if key and r.key then
            same = (r.key == key)
        elseif not r.src[how == "corpse" and "guid" or how] then
            if name and k.m and Lower(name) == Lower(k.m) then
                same = true
            elseif boss and BossFor(dungeon, k.n, k.b or k.m) == boss then
                same = true
            elseif name and FightGroup(dungeon, name) and FightGroup(dungeon, name) == FightGroup(dungeon, k.b or k.m) then
                same = true -- ringoflaw: the fight's event and its boss's death
            elseif key and not name and k.m then        -- a name-only kill learning its GUID
                local known = NameOfNpc(npc)
                same = (known == nil) or (Lower(known) == Lower(k.m))
            elseif not key and r.key and name and not k.m then -- a GUID kill learning its name
                same = true
            elseif how == "party" and not key and not name then -- partykill: the XP line or boss event came first
                same = true
            elseif r.src.party and not r.key and not k.m and name then -- partykill: named a moment later
                same = true
            end
        end
        if same then
            r.src[how == "corpse" and "guid" or how] = true
            if key and not r.key then
                r.key = key
                k.g = 1
                k.n = k.n or npc
                run.killedG[key] = true
                if not k.b then run.seen[key] = true end
            end
            if name and not k.m then k.m = name end
            -- ringoflaw: the fight's kill learns which of its bosses it was
            local _, member = FightGroup(dungeon, name)
            if member and k.b and k.b ~= member.name and FightGroup(dungeon, k.b) == member.fightGroup then
                k.b, k.m = member.name, name
                k.n = k.n or member.npcID
            end
            if k.n and k.m then LearnName(k.n, k.m) end
            if not k.b then ClassifyKill(run, k) if k.b then SetKillTimes(run, k) end end
            -- ruuzlu: the boss event ends a fight with partners
            if how == "boss" and boss and type(boss.killWith) == "table" and (k.wb == boss.name or k.b == boss.name) then
                local waiting = k.wb == boss.name
                EventEndsFight(run, k, boss)
                if waiting and k.b then SetKillTimes(run, k) end
            end
            -- resetsplit: a "dies" line counted first, the boss event now.
            if k.b and how == "boss" then FDJ.RunLogSplitAfterReset(run, BossFor(dungeon, k.n, k.b), k.b) end
            Changed()
            return k
        end
    end

    -- A corpse seen on a nameplate: if a kill of that mob was counted by name
    -- only (no GUID), this is that kill, not a new one.
    if how == "corpse" and key and name then
        for i = #run.kills, 1, -1 do
            local k = run.kills[i]
            if not k.g and k.m and Lower(k.m) == Lower(name) then
                k.g, k.n = 1, k.n or npc
                run.killedG[key] = true
                if not k.b then run.seen[key] = true end
                Changed()
                return k
            end
        end
    end
    if how == "corpse" then how = "guid" end
    if boss or how == "boss" then
        local fresh = FDJ.RunLogSplitAfterReset(run, boss, name)
        if fresh then
            run = fresh
            RunSets(run)
        end
    end

    local kill = { t = Now(), n = npc, m = name, g = key and 1 or nil }
    -- partykill (2.0.4): a kill by your group on a mob the game keeps hidden.
    if how == "party" and not npc and not name then kill.a = 1 end
    ClassifyKill(run, kill)
    if how == "boss" and not kill.b and name then kill.b = name kill.wb = nil end
    if how == "boss" and boss and type(boss.killWith) == "table" and kill.b == boss.name then
        EventEndsFight(run, kill, boss) -- ruuzlu
    end
    if key then
        run.killedG[key] = true
        if not kill.b then run.seen[key] = true end
    end
    if npc and name then LearnName(npc, name) end
    TakePendingXP(kill)
    table.insert(run.kills, kill)
    table.insert(recent, { clock = now, kill = kill, key = key, src = { [how] = true } })
    while #recent > 40 do table.remove(recent, 1) end
    SetKillTimes(run, kill)
    Changed()
    return kill
end

-- ------------------------------------------------------------ XP
local lastXP, lastMax, lastLevel
local chatCredit, chatCreditClock = 0, 0
local questCredit, questCreditClock = 0, 0
local xpQueue = {}

local function ReadXP()
    local ok1, xp = pcall(UnitXP, "player")
    local ok2, max = pcall(UnitXPMax, "player")
    local ok3, lvl = pcall(UnitLevel, "player")
    xp, max, lvl = ok1 and Plain(xp), ok2 and Plain(max), ok3 and Plain(lvl)
    if type(xp) ~= "number" or type(max) ~= "number" or type(lvl) ~= "number" then return nil end
    return xp, max, lvl
end

local function GiveXP(amount)
    if amount <= 0 or not current then return end
    local now = Clock()
    for i = #recent, 1, -1 do
        local r = recent[i]
        if now - r.clock > XP_WINDOW then break end
        if not r.kill.x then
            r.kill.x = amount
            Changed()
            return
        end
    end
    table.insert(pendingXP, { now, amount })
    C_Timer.After(2.2, function()
        local t = Clock()
        for i = #pendingXP, 1, -1 do
            if t - pendingXP[i][1] > 2 then
                if current then current.otherXP = (current.otherXP or 0) + pendingXP[i][2] end
                table.remove(pendingXP, i)
                Changed()
            end
        end
    end)
end

local function ProcessXP()
    local now = Clock()
    if now - chatCreditClock > 3 then chatCredit = 0 end
    if now - questCreditClock > 3 then questCredit = 0 end
    while #xpQueue > 0 do
        local amount = table.remove(xpQueue, 1)
        local used = math.min(amount, chatCredit)
        chatCredit = chatCredit - used
        amount = amount - used
        used = math.min(amount, questCredit)
        questCredit = questCredit - used
        amount = amount - used
        GiveXP(amount)
    end
end

local function OnXPUpdate()
    local xp, max, lvl = ReadXP()
    if not xp then return end
    if lastXP and inside then
        local delta
        if lvl > lastLevel then
            delta = (lastMax - lastXP) + xp
        elseif lvl == lastLevel then
            delta = xp - lastXP
        end
        if delta and delta > 0 then
            table.insert(xpQueue, delta)
            -- The chat line naming the mob may come just after: wait for it.
            C_Timer.After(0.5, ProcessXP)
        end
    end
    lastXP, lastMax, lastLevel = xp, max, lvl
end

-- "<mob> dies, you gain 450 experience."
local function OnXPChat(text)
    text = Plain(text)
    if not inside or type(text) ~= "string" then return end
    local args = Match(Patterns().xp, text)
    if not args then return end
    local name, amount = args[1], Number(args[2])
    if type(name) ~= "string" or not amount or amount <= 0 then return end
    -- "(+225 exp Rested bonus)", "(+40 group bonus)", "(-10 raid penalty)":
    -- part of what the mob gave.
    for sign, n in text:gmatch("%(([%+%-])([%d,%.]+)") do
        n = Number(n)
        if n then amount = amount + (sign == "-" and -n or n) end
    end
    local now = Clock()
    if now - chatCreditClock > 3 then chatCredit = 0 end
    chatCredit = chatCredit + amount
    chatCreditClock = now
    local kill = AddKill(nil, name, "xp")
    if kill and current then
        kill.x = (kill.x or 0) + amount
        Changed()
    elseif current then
        current.otherXP = (current.otherXP or 0) + amount
    end
end

-- ------------------------------------------------------------ seen mobs
-- The dungeon's rares (in test mode: its bosses) that a unit could be, from
-- what the game still tells about it: its classification and level.
function FDJ.RunLogRareCandidates(unit, dungeon, test)
    local okC, cls = pcall(UnitClassification, unit)
    cls = okC and Plain(cls)
    if cls ~= "rare" and cls ~= "rareelite" then return {} end
    local okL, lvl = pcall(UnitLevel, unit)
    lvl = okL and Plain(lvl)
    local d = dungeon and FDJ.DB and FDJ.DB[dungeon]
    local levels = (FDJ.BOSS_LEVELS and dungeon and FDJ.BOSS_LEVELS[dungeon]) or {}
    local killed = {}
    for _, k in ipairs((current and current.kills) or {}) do
        if k.b then killed[k.b] = true end
    end
    local all, byLevel = {}, {}
    for _, b in ipairs((d and d.bosses) or {}) do
        if type(b) == "table" and type(b.name) == "string" and b.rare
            and not b.trackerHidden and not killed[b.name] then
            all[#all + 1] = b
            if type(lvl) == "number" and tonumber(levels[b.name]) == lvl then byLevel[#byLevel + 1] = b end
        end
    end
    -- One rare in the dungeon: that's it. Several: the one with that level,
    -- or all of them when the level doesn't tell.
    if #all <= 1 then return all end
    if #byLevel > 0 then return byLevel end
    return all
end

local function OnUnit(unit)
    if type(unit) == "string" then ObserveUnit(unit) end
    if not inside or type(unit) ~= "string" then return end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or not Plain(exists) then return end
    local okG, guid = pcall(UnitGUID, unit)
    local npc, zone, map, key = ParseGUID(okG and guid or nil)
    local okN, name = pcall(UnitName, unit)
    name = okN and Plain(name) or nil
    -- A rare found alive (by its ID, or by its name when Forever hides IDs
    -- inside instances): its portrait glows on the tracker. A rare found
    -- before the first kill starts the run.
    local dungeon = (current and current.dungeon) or insideDungeon
    local test = FDJ.RUNLOG_TEST_RARES and FDJ.RUNLOG_TEST_RARES[dungeon]
    local found = {}
    local boss = (npc or name) and BossFor(dungeon, npc, name)
    -- ringoflaw: the challenger the fight brought (targeted or seen): the
    -- tracker's Ring of Law entry shows that boss.
    if boss and type(boss.fightGroup) == "string" and current then
        current.groupPick = current.groupPick or {}
        if current.groupPick[boss.fightGroup] ~= boss.name then
            current.groupPick[boss.fightGroup] = boss.name
            Changed()
        end
    end
    if boss and not boss.trackerHidden and (boss.rare or test) then
        found[1] = boss
    elseif not boss and not npc and not name then
        -- ID and name both hidden: a unit the game calls "rare" is one of
        -- this dungeon's rares not found yet, picked by its level when the
        -- journal knows the rares' levels.
        found = FDJ.RunLogRareCandidates and FDJ.RunLogRareCandidates(unit, dungeon, test) or {}
    end
    if #found > 0 then
        local okD, dead = pcall(UnitIsDead, unit)
        if not (okD and Plain(dead)) then
            local run = current or EnsureRun()
            if run then
                run.rareSeen = run.rareSeen or {}
                local new = false
                for _, b in ipairs(found) do
                    if not run.rareSeen[b.name] then
                        run.rareSeen[b.name] = Now()
                        new = true
                    end
                end
                if new then
                    if FDJ.RunLogRareSpotted then pcall(FDJ.RunLogRareSpotted, run, found[1], name) end
                    Changed()
                end
            end
        end
    end
    if not npc then return end
    LearnName(npc, name)
    local okP, pc = pcall(UnitPlayerControlled, unit)
    if okP and Plain(pc) then return end
    local okA, hostile = pcall(UnitCanAttack, "player", unit)
    if not okA or not Plain(hostile) then return end
    local okT, ctype = pcall(UnitCreatureType, unit)
    ctype = okT and Plain(ctype)
    if ExcludedType(ctype) then return end
    CheckZone(zone, map)
    local run = current
    if not run then return end
    RunSets(run)
    local dungeon = run.dungeon or insideDungeon
    local bossRec = BossFor(dungeon, npc, name)
    local isBoss = bossRec ~= nil
    if not isBoss and not run.seen[key] then
        run.seen[key] = true
        Changed()
    end
    local okD, dead = pcall(UnitIsDead, unit)
    -- A corpse no event told about (killed out of range): count it.
    if okD and Plain(dead) and not run.killedG[key] then AddKill(guid, name, "corpse") end
end

-- ------------------------------------------------------------ need rolls
local rollLinks = {}   -- rollID -> link

local function RollLink(rollID)
    if rollLinks[rollID] then return rollLinks[rollID] end
    if GetLootRollItemLink then
        local ok, link = pcall(GetLootRollItemLink, rollID)
        link = ok and Plain(link)
        if type(link) == "string" then rollLinks[rollID] = link return link end
    end
end

local function SetNeedResult(need, result)
    if need.res == result then return end
    need.res = result
    Changed()
end

-- A Need roll on this item still waiting for its result; with orLost, also
-- one marked lost in the last 15 minutes (a later "you got it" wins over it).
local function PendingNeedFor(itemID, orLost)
    local found
    for _, run in ipairs(Store().runs) do
        if not run.closed then
            for _, need in ipairs(run.needs or {}) do
                if need.id == itemID then
                    if need.res == nil then return need end
                    if orLost and need.res == "lost" and Now() - (need.at or 0) < 900 then found = found or need end
                end
            end
        end
    end
    return found
end

-- A Need roll: from the roll buttons (RollOnLoot) or, if another addon rolls
-- some other way, from the "You have selected Need for" chat line.
local function OnNeed(rollID, link)
    if not inside then return end
    link = link or (rollID and RollLink(rollID))
    local id = ItemIDOf(link)
    if not id then return end
    if not rollID then
        for r, l in pairs(rollLinks) do
            if ItemIDOf(l) == id then rollID = r end
        end
    end
    local run = EnsureRun()
    if not run then return end
    local now = Now()
    for _, need in ipairs(run.needs) do
        if (rollID and need.roll == rollID) or (need.id == id and now - (need.at or 0) < 5) then
            need.roll = need.roll or rollID
            return
        end
    end
    table.insert(run.needs, { roll = rollID, at = now, id = id, link = link, before = ItemCount(id) })
    Changed()
end

-- The roll ended. If no chat line said who won, the bags tell.
local function OnRollEnded(rollID)
    C_Timer.After(3, function()
        for _, run in ipairs(Store().runs) do
            if not run.closed then
                for _, need in ipairs(run.needs or {}) do
                    if need.roll == rollID and need.res == nil and Now() - (need.at or 0) < 900 then
                        SetNeedResult(need, ItemCount(need.id) > (need.before or 0) and "won" or "lost")
                    end
                end
            end
        end
    end)
    -- The item can reach the bags a little later: look again.
    C_Timer.After(15, function()
        for _, run in ipairs(Store().runs) do
            for _, need in ipairs(run.needs or {}) do
                if need.roll == rollID and need.res == "lost" and ItemCount(need.id) > (need.before or 0) then
                    SetNeedResult(need, "won")
                end
            end
        end
    end)
end

-- Kills saved with neither name nor ID were the same deaths counted twice
-- (1.7.5 fix): dropped from the saved runs. Not the kills your group landed
-- on a mob the game keeps hidden (k.a, 2.0.4): those are real. Dropping them
-- after each loading screen emptied the run, and the next step outside
-- deleted it.
local function DropNamelessKills()
    for _, run in ipairs(Store().runs) do
        local kept = {}
        for _, k in ipairs(run.kills or {}) do
            if k.m or k.n or k.b or k.a then kept[#kept + 1] = k end
        end
        run.kills = kept
    end
end

-- Rolls marked lost although the item is in the bags (1.7.5 fix): won.
local function FixLostNeeds()
    for _, run in ipairs(Store().runs) do
        for _, need in ipairs(run.needs or {}) do
            if need.res == "lost" and Now() - (need.at or 0) < 6 * 3600 and ItemCount(need.id) > (need.before or 0) then
                SetNeedResult(need, "won")
            end
        end
    end
end

-- ------------------------------------------------------------ boss loot
-- What each boss dropped, shown when hovering its portrait. From the corpse's
-- loot window (the source GUID says which boss), from loot rolls, and from
-- the "won" / "receives loot" lines: an item in a killed boss's journal loot
-- is that boss's; any other blue or better roll soon after a boss kill too.
local function JournalHas(dungeon, bossName, itemID)
    local d = dungeon and FDJ.DB and FDJ.DB[dungeon]
    for _, b in ipairs((d and d.bosses) or {}) do
        if type(b) == "table" and b.name == bossName then
            for _, list in ipairs({ b.loot or {}, b.probableLoot or {} }) do
                for _, item in ipairs(list) do
                    if type(item) == "table" and tonumber(item[1]) == itemID then return true end
                end
            end
        end
    end
    return false
end

local function GoodQuality(link)
    local q = FDJ.RunLogItemQuality and FDJ.RunLogItemQuality(ItemIDOf(link), link)
    return type(q) == "number" and q >= 3
end

-- Who chose Need or Greed on what (from the roll lines), so the winner's
-- roll can be shown next to the item. itemID -> lower-case name -> kind
local rollChoice = {}
local function SetChoice(link, name, kind)
    local id = ItemIDOf(link)
    if not id or type(name) ~= "string" then return end
    rollChoice[id] = rollChoice[id] or {}
    rollChoice[id][name:lower()] = kind
end
local function ChoiceOf(id, name)
    local t = id and rollChoice[id]
    return t and type(name) == "string" and t[name:lower()] or nil
end
-- The number each player rolled ("Need Roll - 87 for <item> by <name>").
-- itemID -> lower-case name -> number
local rollValue = {}
local function SetRollValue(link, name, n)
    local id = ItemIDOf(link)
    n = tonumber(n)
    if not id or not n or type(name) ~= "string" then return end
    rollValue[id] = rollValue[id] or {}
    rollValue[id][name:lower()] = n
end
local function RollOf(id, name)
    local t = id and rollValue[id]
    return t and type(name) == "string" and t[name:lower()] or nil
end

local function AddBossLoot(link, sourceNpc, winner, fromRoll)
    local run = current
    local id = ItemIDOf(link)
    if not run or not id then return end
    -- Already listed under a boss (the roll came first): add who won it.
    for i = #run.kills, 1, -1 do
        for _, e in ipairs(run.kills[i].loot or {}) do
            if e.id == id and (not e.w or e.w == winner) then
                if winner and not e.w then e.w = winner end
                if e.w and not e.r then e.r = ChoiceOf(id, e.w) end
                if e.w and not e.n then e.n = RollOf(id, e.w) end
                Changed()
                return
            end
        end
    end
    local target
    for i = #run.kills, 1, -1 do
        local k = run.kills[i]
        if k.b then
            if sourceNpc then
                if k.n == sourceNpc then target = k break end
            elseif JournalHas(run.dungeon or insideDungeon, k.b, id) then
                target = k
                break
            end
        end
    end
    if not target and not sourceNpc and fromRoll and GoodQuality(link) then
        for i = #run.kills, 1, -1 do
            local k = run.kills[i]
            if k.b then
                if Now() - (k.t or 0) <= 180 then target = k end
                break
            end
        end
    end
    if not target then return end
    target.loot = target.loot or {}
    for _, e in ipairs(target.loot) do
        if e.id == id then
            if winner and not e.w then e.w = winner end
            if e.w and not e.r then e.r = ChoiceOf(id, e.w) end
            if e.w and not e.n then e.n = RollOf(id, e.w) end
            Changed()
            return
        end
    end
    table.insert(target.loot, { id = id, link = link, w = winner, r = winner and ChoiceOf(id, winner) or nil,
        n = winner and RollOf(id, winner) or nil })
    Changed()
end

local function OnLootWindow()
    if not inside or not current or not GetNumLootItems then return end
    local okN, n = pcall(GetNumLootItems)
    n = okN and Plain(n)
    if type(n) ~= "number" then return end
    for slot = 1, n do
        local okL, link = pcall(GetLootSlotLink, slot)
        link = okL and Plain(link)
        if type(link) == "string" and GetLootSourceInfo then
            local okS, guid = pcall(GetLootSourceInfo, slot)
            local npc = ParseGUID(okS and guid or nil)
            if npc then AddBossLoot(link, npc) end
        end
    end
end

local function PlayerName()
    local ok, name = pcall(UnitName, "player")
    name = ok and Plain(name)
    return type(name) == "string" and name or (_G.YOU or "You")
end

-- The winner named in "<name> won: <item>" can be this character (some
-- clients name you instead of saying "You won"), also with a second name.
local function IsMe(name)
    name = Plain(name)
    if type(name) ~= "string" then return false end
    local me = PlayerName():lower()
    name = name:lower()
    if name == me or name == ((_G.YOU or "You"):lower()) then return true end
    return name:sub(1, #me + 1) == me .. " " or name:sub(1, #me + 1) == me .. "-"
end

-- What this character rolled on an item (any of its names).
local function MyRoll(id)
    local t = id and rollValue[id]
    if not t then return nil end
    local direct = t[PlayerName():lower()]
    if direct then return direct end
    for name, n in pairs(t) do
        if IsMe(name) then return n end
    end
end
local function SetNeedRoll(need)
    if need and not need.n then
        local n = MyRoll(need.id)
        if n then need.n = n Changed() end
    end
end
-- A roll number arrived: put it on this character's Need and on the boss
-- loot it belongs to (if the winner is already known).
local function OnRollNumber(link, name, n)
    SetRollValue(link, name, n)
    local id = ItemIDOf(link)
    if not id then return end
    if IsMe(name) then
        for _, run in ipairs(Store().runs) do
            for _, need in ipairs(run.needs or {}) do
                if need.id == id and Now() - (need.at or 0) < 900 then SetNeedRoll(need) end
            end
        end
    end
    local run = current
    for _, k in ipairs((run and run.kills) or {}) do
        for _, e in ipairs(k.loot or {}) do
            if e.id == id and e.w and not e.n then
                local v = RollOf(id, e.w)
                if v then e.n = v Changed() end
            end
        end
    end
end

local function OnLootChat(text)
    text = Plain(text)
    if type(text) ~= "string" then return end
    local p = Patterns()
    local args = Match(p.youWon, text)
    if args then
        AddBossLoot(args[1], nil, PlayerName())
        local need = PendingNeedFor(ItemIDOf(args[1]), true)
        if need then SetNeedResult(need, "won") SetNeedRoll(need) end
        return
    end
    args = Match(p.won, text)
    if args then
        AddBossLoot(args[2], nil, args[1])
        local mine = IsMe(args[1])
        local need = PendingNeedFor(ItemIDOf(args[2]), mine)
        if need then SetNeedResult(need, mine and "won" or "lost") SetNeedRoll(need) end
        return
    end
    args = Match(p.allPassed, text)
    if args then
        local need = PendingNeedFor(ItemIDOf(args[1]))
        if need then SetNeedResult(need, "lost") end
        return
    end
    args = Match(p.needSelf, text)
    if args then SetChoice(args[1], PlayerName(), "need") OnNeed(nil, args[1]) return end
    args = Match(p.greedSelf, text)
    if args then SetChoice(args[1], PlayerName(), "greed") return end
    args = Match(p.needOther, text)
    if args then SetChoice(args[2], args[1], "need") return end
    args = Match(p.greedOther, text)
    if args then SetChoice(args[2], args[1], "greed") return end
    args = Match(p.rolledNeed, text) or Match(p.rolledNeedBonus, text)
    if args then SetChoice(args[2], args[3], "need") OnRollNumber(args[2], args[3], Number(args[1])) return end
    args = Match(p.rolledGreed, text)
    if args then SetChoice(args[2], args[3], "greed") OnRollNumber(args[2], args[3], Number(args[1])) return end
    args = Match(p.lootSelf, text)
    if args then
        AddBossLoot(args[1], nil, PlayerName())
        -- Receiving the item settles a Need roll on it: won.
        local need = PendingNeedFor(ItemIDOf(args[1]), true)
        if need then SetNeedResult(need, "won") SetNeedRoll(need) end
        return
    end
    args = Match(p.lootOther, text)
    if args then AddBossLoot(args[2], nil, args[1]) end
end

if hooksecurefunc and RollOnLoot then
    hooksecurefunc("RollOnLoot", function(rollID, rollType)
        if rollType == 1 then pcall(OnNeed, rollID) end
        if rollType == 1 or rollType == 2 then
            pcall(SetChoice, RollLink(rollID), PlayerName(), rollType == 1 and "need" or "greed")
        end
    end)
end

-- ------------------------------------------------------------ entering / leaving
local function Ghost()
    local ok, ghost = pcall(UnitIsGhost, "player")
    if ok and Plain(ghost) then return true end
    local ok2, dead = pcall(UnitIsDeadOrGhost, "player")
    return ok2 and Plain(dead) and true or false
end

local function CloseStale()
    local now = Now()
    for _, run in ipairs(Store().runs) do
        if not run.closed and run ~= current then
            local since = run.outside and run.outside.t or run.lastSeen or run.created or 0
            local window = run.completed and RESUME_DONE or RESUME_OPEN
            if now - since > window then CloseRun(run) end
        end
    end
end

local function Leave()
    local run = current
    inside, insideMap, insideDungeon = false, nil, nil
    unitEvidence = { guid = {}, name = {} }
    current = nil
    recent = {}
    if not run or run.closed then return end
    run.lastSeen = Now()
    if IsEmpty(run) then CloseRun(run) return end
    -- Leaving after the final boss is just the end of the run, not a break.
    if run.completed then CloseRun(run) return end
    local exit = { t = Now(), why = Ghost() and "released" or "stepped" }
    table.insert(run.exits, exit)
    run.outside = exit
    Changed()
end

local function Enter(map, dungeon)
    if not inside or insideMap ~= map then unitEvidence = { guid = {}, name = {} } end
    inside, insideMap, insideDungeon = true, map, dungeon
    recent = {}
    local run = OpenRunOf(map)
    if run then
        -- 2.0.3: a run saved without its dungeon (not recognised on that
        -- client's language): name it by the instance ID and see whether
        -- its bosses were all down after all.
        if not (run.dungeon and FDJ.DB and FDJ.DB[run.dungeon]) and FDJ.RunLogFixDungeon then
            pcall(FDJ.RunLogFixDungeon, run)
        end
        if run.dungeon and not run.completed then FixBossKills(run) end
        local since = run.outside and run.outside.t or run.lastSeen
        local window = run.completed and RESUME_DONE or RESUME_OPEN
        -- 2.0.3: a run whose bosses are all down is over: going back in after
        -- leaving starts a new run instead of adding to it (runs completed
        -- after an update stayed open and swallowed the next run). A /reload
        -- inside keeps it, so its tracker can still be shown.
        if (run.completed and run.outside) or (since and Now() - since > window) then
            CloseRun(run)
            run = nil
        end
    end
    if run then
        if run.outside then
            run.outside.back = Now()
            run.outside = nil
        end
        current = run
        if not run.dungeon and dungeon then run.dungeon = dungeon end
        -- 2.0.3: back in a shared instance (Scarlet Monastery, Dire Maul,
        -- Stratholme, Blackrock Spire) after a corpse run, /reload or relog:
        -- it's the run's wing. The tracker hid, and /dj tracker found no run,
        -- until a kill proved the wing again.
        if not insideDungeon and run.dungeon and FDJ.RunLogWingGroups and FDJ.RunLogWingGroups[map]
            and FDJ.DB and FDJ.DB[run.dungeon] then
            insideDungeon = run.dungeon
        end
        Changed()
    end
    CloseStale()
end

local function OnWorld()
    local isIn, map, dungeon = InDungeon()
    if isIn then
        if inside and insideMap == map and current then
            -- /reload or a loading screen inside: nothing changes.
            insideDungeon = dungeon or insideDungeon
            return
        end
        if inside and current then Leave() end
        Enter(map, dungeon)
    elseif inside then
        Leave()
        CloseStale()
    else
        CloseStale()
    end
end

-- The dungeon name may resolve a moment after zoning in (wings, subzones).
local function RefreshDungeon()
    if not inside then return end
    local isIn, map, dungeon = InDungeon()
    if isIn and map == insideMap and dungeon then
        ApplyWing(dungeon, false)
        Changed()
    end
end

-- instancereset: "<Dungeon> has been reset." The group reset the dungeon,
-- so an unfinished run of it is over: its tracker goes away now, and going
-- back in starts a new run. (Corpse runs and vendor trips don't reset the
-- dungeon, so they still continue the same run.)
--
-- 2.0.4: only the player who resets gets that line, so only their own run
-- ends by itself. Everyone else ends theirs with the tracker's reset button
-- (or /dj reset). Nothing from other players (chat, addon messages) is
-- taken as a reset: anyone could send it.

-- The names a run goes by: the game's instance name, the journal's, and the
-- journal's in this client's language (all lower case).
function FDJ.RunLogRunNames(run)
    local names = {}
    for _, s in ipairs({ run.instanceName, run.dungeon }) do
        s = Lower(s)
        if s then names[#names + 1] = s end
    end
    if run.dungeon and FDJ.LocalizeDungeonName then
        local ok, loc = pcall(FDJ.LocalizeDungeonName, run.dungeon)
        loc = ok and Lower(loc)
        if loc then names[#names + 1] = loc end
    end
    return names
end

-- Ends the unfinished runs we are outside of that test(run) says were reset.
function FDJ.RunLogEndReset(test)
    local ended = {}
    for _, run in ipairs(Store().runs) do
        if not run.closed and run ~= current and test(run) then ended[#ended + 1] = run end
    end
    for _, run in ipairs(ended) do
        run.resetAt = Now()
        run.endedAt = run.endedAt or Now()
        CloseRun(run)
    end
    return ended
end

local function NamedTest(name)
    return function(run)
        for _, n in ipairs(FDJ.RunLogRunNames(run)) do
            if n == name then return true end
        end
        return false
    end
end

local function OnInstanceReset(text)
    text = Plain(text)
    if type(text) ~= "string" then return end
    local args = Match(Patterns().reset, text)
    local name = args and Lower(args[1])
    if not name then return end
    FDJ.RunLogEndReset(NamedTest(name))
end

-- ------------------------------------------------------------ events
local events = CreateFrame("Frame")
for _, e in ipairs({
    "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
    "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "PLAYER_DEAD", "QUEST_TURNED_IN",
    "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
    "ENCOUNTER_END", "BOSS_KILL", "PARTY_KILL", "UNIT_DIED", "GOSSIP_SHOW", "UNIT_TARGET",
    "CHAT_MSG_COMBAT_XP_GAIN", "CHAT_MSG_COMBAT_HOSTILE_DEATH", "CHAT_MSG_LOOT",
    "START_LOOT_ROLL", "CANCEL_LOOT_ROLL", "LOOT_OPENED", "LOOT_READY", "PLAYER_MONEY", "CHAT_MSG_SYSTEM",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
}) do
    pcall(events.RegisterEvent, events, e)
end

-- Money: what the run earned (copper, gains only: buying or repairing
-- doesn't take it back), counted while inside. At the level cap, where no
-- XP comes, the page and the tracker show it instead of the mobs' XP.
local lastMoney
local function ReadMoney()
    if not GetMoney then return nil end
    local ok, m = pcall(GetMoney)
    m = ok and Plain(m)
    return type(m) == "number" and m or nil
end
local function IsCapped()
    if IsXPUserDisabled then
        local ok, off = pcall(IsXPUserDisabled)
        if ok and off == true then return true end
    end
    local okL, level = pcall(UnitLevel, "player")
    level = okL and Plain(level)
    local max = 60
    if GetMaxPlayerLevel then
        local okM, m = pcall(GetMaxPlayerLevel)
        if okM and type(m) == "number" and m > 0 then max = m end
    end
    return type(level) == "number" and level >= max
end
FDJ.RunLogIsCapped = IsCapped
local function OnMoney()
    local now = ReadMoney()
    if not now then return end
    local before = lastMoney
    lastMoney = now
    if not before or now <= before or not inside then return end
    local run = current
    if not run then return end
    run.money = (run.money or 0) + (now - before)
    if IsCapped() then run.capped = true end
    Changed()
end

events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_MONEY" then
        OnMoney()
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        if not lastMoney then lastMoney = ReadMoney() end
        if not lastXP then lastXP, lastMax, lastLevel = ReadXP() end
        OnWorld()
        if C_Timer and C_Timer.After then
            C_Timer.After(2, RefreshDungeon)
            C_Timer.After(5, FixLostNeeds)
            C_Timer.After(1, DropNamelessKills)
            -- bossnames: the game's boss names, then saved runs repaired.
            C_Timer.After(8, function()
                if not (InCombatLockdown and InCombatLockdown()) then pcall(LearnFromJournal) end
                pcall(FixBossKillsAll)
            end)
        end
    elseif event == "PLAYER_LEAVING_WORLD" then
        if current then current.lastSeen = Now() end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        RefreshDungeon()
    elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
        OnXPUpdate()
    elseif event == "QUEST_TURNED_IN" then
        local _, xp = ...
        xp = tonumber(Plain(xp))
        if xp and xp > 0 then
            if Clock() - questCreditClock > 3 then questCredit = 0 end
            questCredit = questCredit + xp
            questCreditClock = Clock()
        end
    elseif event == "PLAYER_DEAD" then
        if inside then
            local run = EnsureRun()
            if run then
                run.deaths = (run.deaths or 0) + 1
                run.deathTimes = run.deathTimes or {}
                table.insert(run.deathTimes, Now())
                Changed()
            end
        end
    elseif event == "GOSSIP_SHOW" then
        OnPusillinGossip()
    elseif event == "UNIT_TARGET" then
        ObserveTargets()
    elseif event == "PLAYER_TARGET_CHANGED" then
        OnUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        OnUnit("mouseover")
    elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        OnUnit((...))
    elseif event == "PARTY_KILL" then
        local _, target = ...
        -- partykill (2.0.4): inside a dungeon Forever hides who died (secret
        -- GUIDs) and has no "dies" chat lines at all. The event itself still
        -- says your group landed a killing blow: count it, even without XP.
        local sig = FDJ.RunLogSignals
        if Plain(target) == nil then
            sig.hidden = sig.hidden + 1
            AddKill(nil, nil, "party")
        else
            sig.plain = sig.plain + 1
            AddKill(target, nil)
        end
    elseif event == "UNIT_DIED" then
        local guid = ...
        -- Only mobs: something the group fought (seen as hostile) or a boss.
        local npc = ParseGUID(guid)
        if npc then AddKill(guid, nil) end
    elseif event == "ENCOUNTER_END" or event == "BOSS_KILL" then
        local id, name, success = ...
        if event == "ENCOUNTER_END" then
            success = select(5, ...)
        else
            success = 1
        end
        id, name = Plain(id), Plain(name)
        -- bossids (2.0.4): every boss event the game sends is noted (ID, the
        -- game's name, the dungeon), so /dj bossids can show which bosses
        -- have one in Forever. Forever's Adventure Guide has no dungeons.
        if (success == 1 or success == true) and tonumber(id) then
            ForeverDungeonJournalDB = ForeverDungeonJournalDB or {}
            local db = ForeverDungeonJournalDB
            db.bossEvents = type(db.bossEvents) == "table" and db.bossEvents or {}
            local e = db.bossEvents[tonumber(id)] or {}
            e.name = type(name) == "string" and name or e.name
            e.dungeon = (current and current.dungeon) or insideDungeon or e.dungeon
            e.map = insideMap or e.map
            e.n = (e.n or 0) + 1
            e.last = Now()
            db.bossEvents[tonumber(id)] = e
        end
        if FDJ.RunLogEncounterName then name = FDJ.RunLogEncounterName(id, name) end
        if (success == 1 or success == true) and type(name) == "string" then
            FDJ.RunLogSignals.boss = FDJ.RunLogSignals.boss + 1
            AddKill(nil, name, "boss")
        end
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        FDJ.RunLogSignals.xp = FDJ.RunLogSignals.xp + 1
        OnXPChat((...))
    elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        local text = Plain((...))
        if inside and type(text) == "string" then
            local p = Patterns()
            local args = Match(p.slain, text) or Match(p.dies, text)
            if args and type(args[1]) == "string" then AddKill(nil, args[1], "death") end
        end
    elseif event == "CHAT_MSG_LOOT" then
        OnLootChat((...))
    elseif event == "CHAT_MSG_SYSTEM" then
        OnInstanceReset((...))
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        FDJ.RunLogNoteFight(event == "PLAYER_REGEN_DISABLED")
    elseif event == "START_LOOT_ROLL" then
        local rollID = ...
        if rollID then
            local link = RollLink(rollID)
            if link then AddBossLoot(link, nil, nil, true) end
        end
    elseif event == "LOOT_OPENED" or event == "LOOT_READY" then
        OnLootWindow()
    elseif event == "CANCEL_LOOT_ROLL" then
        local rollID = ...
        if rollID then OnRollEnded(rollID) end
    end
end)

-- /dj rlog: what the recorder sees of your target (for testing).
function FDJ.RunLogDebug()
    local function show(v)
        if type(issecretvalue) == "function" and issecretvalue(v) then return "SECRET" end
        return tostring(v)
    end
    local okG, guid = pcall(UnitGUID, "target")
    local okN, name = pcall(UnitName, "target")
    local npc = ParseGUID(okG and guid or nil)
    local dungeon = (current and current.dungeon) or insideDungeon
    local boss = BossFor(dungeon, npc, Plain(name))
    Say("inside=" .. tostring(inside) .. " dungeon=" .. tostring(dungeon) .. " run=" .. tostring(current and current.id))
    Say("target guid=" .. show(okG and guid) .. " name=" .. show(okN and name) .. " npc=" .. tostring(npc))
    Say("wing evidence=" .. tostring(WingFor(npc, Plain(name)))
        .. " eligible=" .. tostring(EligibleKill(Plain(guid), npc, Plain(name), "guid")))
    Say("boss=" .. tostring(boss and boss.name) .. " rare=" .. tostring(boss and (boss.rare or (FDJ.RUNLOG_TEST_RARES and FDJ.RUNLOG_TEST_RARES[dungeon])) or false))
    local function try(fn, ...) local ok, v = pcall(fn, ...) return ok and show(v) or "error" end
    Say("class=" .. try(UnitClassification, "target") .. " level=" .. try(UnitLevel, "target")
        .. " hpmax=" .. try(UnitHealthMax, "target") .. " type=" .. try(UnitCreatureType, "target")
        .. " dead=" .. try(UnitIsDead, "target"))
    local cands = {}
    for _, b in ipairs(FDJ.RunLogRareCandidates("target", dungeon, FDJ.RUNLOG_TEST_RARES and FDJ.RUNLOG_TEST_RARES[dungeon])) do cands[#cands + 1] = b.name end
    Say("could be: " .. (#cands > 0 and table.concat(cands, ", ") or "nothing"))
    local seen = {}
    for n in pairs((current and current.rareSeen) or {}) do seen[#seen + 1] = n end
    Say("rares seen: " .. (#seen > 0 and table.concat(seen, ", ") or "none"))
end

-- ------------------------------------------------------------ for the page
FDJ.RunLog = {
    Runs = function() return Store().runs end,
    Current = function() return current end,
    IsInside = function() return inside end,
    InsideMap = function() return inside and insideMap or nil end,
    IsAwaitingWing = AwaitingWing,
    FixBossKills = function(run) return FixBossKills(run) end,
    TrashKilled = TrashKilled,
    TrashSeen = TrashSeen,
    TrashTotal = function(run)
        local learned = run.dungeon and tonumber(Account().runLogTrashTotal[run.dungeon]) or 0
        return math.max(learned, TrashSeen(run), TrashKilled(run))
    end,
    NpcName = NameOfNpc,
    -- clientnames (2.0.3): a boss's name from the game client.
    AddAlias = function(npc, name)
        name = Plain(name)
        if not tonumber(npc) or type(name) ~= "string" or name == "" then return false end
        Account().runLogNames[tonumber(npc)] = name
        return AddBossAlias(tonumber(npc), name)
    end,
    FixAll = function() return FixBossKillsAll and FixBossKillsAll() end,
    -- groupreset (2.0.4): end a run by hand (the dungeon was reset and
    -- nothing told us); the next kill starts a new one.
    EndRun = function(run)
        run = run or current
        if not run or run.closed then return false end
        run.resetAt = Now()
        run.endedAt = Now()
        CloseRun(run)
        recent = {}
        return true
    end,
    Delete = function(run)
        local log = Store()
        for i = #log.runs, 1, -1 do
            if log.runs[i] == run then
                table.remove(log.runs, i)
                if current == run then current = nil end
                Changed()
                return true
            end
        end
    end,
    -- For tests and the dev command: the pattern builder.
    MakePattern = MakePattern,
    Match = Match,
}

-- ------------------------------------------------------------ the party
-- Who did the run: everyone in the group while the run is recorded
-- (run.party[name] = class token), for the run page's Party button. Names
-- the game hides (secret values) are skipped.
do
    local function Record()
        if not (inside and current) or current.closed then return end
        local function Add(unit)
            if not (UnitExists and UnitExists(unit)) then return end
            local name, realm = UnitName(unit)
            name, realm = Plain(name), Plain(realm)
            if type(name) ~= "string" or name == "" or name == UNKNOWNOBJECT then return end
            if type(realm) == "string" and realm ~= "" then name = name .. "-" .. realm end
            local _, class = UnitClass(unit)
            current.party = current.party or {}
            if not current.party[name] then
                current.party[name] = Plain(class) or true
                Changed()
            end
        end
        Add("player")
        local raid = IsInRaid and IsInRaid()
        local n = GetNumGroupMembers and GetNumGroupMembers() or 0
        if raid then
            for i = 1, n do Add("raid" .. i) end
        else
            for i = 1, math.max(0, n - 1) do Add("party" .. i) end
        end
    end
    local f = CreateFrame("Frame")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:SetScript("OnEvent", function() pcall(Record) end)
    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(10, function() pcall(Record) end)
    end
end
