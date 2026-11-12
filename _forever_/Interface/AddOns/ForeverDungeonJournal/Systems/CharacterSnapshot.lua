-- FDJ3 wire snapshot. No changes or new locals in Core/Journal.lua.
local FDJ = _G.ForeverDungeonJournal_NS
if not FDJ then return end
local function Array() return setmetatable({}, {__fdjArray = true}) end
local function JSON(v)
    local kind = type(v)
    if kind == "nil" then return "null" end
    if kind == "boolean" then return v and "true" or "false" end
    if kind == "number" then assert(v == v and math.abs(v) < math.huge); return tostring(v) end
    if kind == "string" then
        return '"' .. v:gsub('[%z\1-\31\\"]', function(c)
            return string.format('\\u%04x', string.byte(c))
        end) .. '"'
    end
    assert(kind == "table", "Unsupported export value")
    local out = {}
    if getmetatable(v) and getmetatable(v).__fdjArray then
        for i, value in ipairs(v) do out[i] = JSON(value) end
        return '[' .. table.concat(out, ',') .. ']'
    end
    local keys = {}
    for k in pairs(v) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do out[#out+1] = JSON(k) .. ':' .. JSON(v[k]) end
    return '{' .. table.concat(out, ',') .. '}'
end
FDJ.ExportJSON = JSON
local function Slug(s)
    return (s:lower():gsub("\226\128\153", ""):gsub("'", ""):gsub('[^a-z0-9]+','-'):gsub('^%-+',''):gsub('%-+$',''))
end
local function Label(fn, value)
    if fn then local ok, s = pcall(fn, value); if ok and type(s) == 'string' then return s end end
    return value
end
local function SnapshotRun(r, now)
    local start = r.firstTrash or r.firstKill
    local stop = r.finalKill or r.lastBoss
    if stop and start and stop < start then start = r.firstKill or start end
    local duration
    if start then
        if r.completed and stop then duration = stop-start
        elseif not r.closed and FDJ.RunLog.Current() == r then duration = now-start
        elseif stop then duration = stop-start end
    end
    local out = {dungeon=r.dungeon or r.instanceName or '?', created=r.created or now,
        start=start, ended=r.finalKill or r.closed, completed=not not r.completed, closed=not not r.closed,
        duration=duration, capped=not not r.capped, money=r.money or 0, deaths=r.deaths or 0,
        xp=0, bosses=Array(), trash=Array(), needs=Array(), exits=Array(), deathTimes=Array(),
        trashKilled=FDJ.RunLog.TrashKilled(r), trashTotal=FDJ.RunLog.TrashTotal(r)}
    -- closed is a boolean in older saves; ended is always a timestamp or absent.
    if type(out.ended) ~= 'number' then out.ended = nil end
    local killed, shown, trash = {}, {}, {}
    for _, k in ipairs(r.kills or {}) do
        out.xp = out.xp + (k.x or 0)
        if k.b and not killed[k.b] then killed[k.b] = k end
        if not k.b and not k.wb and not k.p then
            local n = k.m or FDJ.RunLog.NpcName(k.n) or '?'
            local e = trash[n] or {name=n,count=0,xp=0}; trash[n]=e
            e.count=e.count+1; e.xp=e.xp+(k.x or 0)
        end
    end
    local function Boss(b)
        shown[b.name]=true
        local k=killed[b.name]
        out.bosses[#out.bosses+1]={name=b.name,label=Label(FDJ.LocalizeBossName,b.name),npcID=b.npcID,
            rare=not not b.rare, state=k and 'killed' or (b.rare and not (r.rareSeen and r.rareSeen[b.name]) and 'not found' or 'not killed'),
            at=k and k.t, xp=k and k.x}
    end
    local d=FDJ.DB and FDJ.DB[r.dungeon]
    for _, b in ipairs(d and d.bosses or {}) do if not b.trash and not b.recipeTab and b.name then Boss(b) end end
    for _, k in ipairs(r.kills or {}) do if k.b and not shown[k.b] then Boss({name=k.b}) end end
    for _, e in pairs(trash) do out.trash[#out.trash+1]=e end
    table.sort(out.trash,function(a,b) if a.count~=b.count then return a.count>b.count end return a.name<b.name end)
    for _, n in ipairs(r.needs or {}) do
        out.needs[#out.needs+1]={id=n.id, name=type(n.link)=='string' and n.link:match('%[(.-)%]') or nil,
            quality=FDJ.RunLogItemQuality and FDJ.RunLogItemQuality(n.id,n.link), result=n.res or 'rolling',roll=n.n,at=n.at}
    end
    for _, e in ipairs(r.exits or {}) do
        if not (r.finalKill and e.t>=r.finalKill) then
            out.exits[#out.exits+1]={at=e.t,why=e.why=='released' and 'released' or 'stepped',
                duration=e.back and e.back-e.t or (not r.closed and now-e.t or nil), open=not e.back and not r.closed}
        end
    end
    for _, t in ipairs(r.deathTimes or {}) do out.deathTimes[#out.deathTimes+1]=t end
    return out
end
function FDJ.BuildCharacterSnapshot()
    ForeverDungeonJournalCharacterDB = ForeverDungeonJournalCharacterDB or {}
    local db=ForeverDungeonJournalCharacterDB
    if type(db.exportKey)~='string' or #db.exportKey<16 then
        -- WoW exposes no cryptographic RNG. Persist 48 draws; never reseed the shared RNG.
        local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
        local key={}
        for i=1,48 do local n=math.random(1,#chars); key[i]=chars:sub(n,n) end
        db.exportKey=table.concat(key)
    end
    local _, race=UnitRace('player'); local _, class=UnitClass('player')
    local now=(GetServerTime and GetServerTime()) or time()
    local faction=UnitFactionGroup('player') or 'Unknown'
    local metadata=(C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local out={v=3,name=UnitName('player'),realm=GetRealmName(),raceToken=race or '',classToken=class or '',
        level=UnitLevel('player'),faction=faction,version=metadata and metadata('ForeverDungeonJournal','Version') or '2.0.4',
        exportedAt=now,exportKey=db.exportKey,rpg=FDJ.IsRPGMode and FDJ.IsRPGMode() or false,
        completed=Array(),lost=Array(),inLog=Array(),dungeons=Array(),runs=Array()}
    local seen={}
    for _, name in ipairs(FDJ.ORDER or {}) do
        local d=FDJ.DB[name]
        local row={name=name,label=Label(FDJ.LocalizeDungeonName,name),slug=Slug(name),level=tostring(d.level or ''),
            cleared=not not (db.rpgKills and db.rpgKills[name]),locked=FDJ.IsDungeonLocked and FDJ.IsDungeonLocked(name) or false,
            previewOnly=not not d.previewOnly,quests=Array(),bosses=Array(),done=0,total=0}
        for _, q in ipairs(d.quests or {}) do
            if q.id then
                local done=FDJ.QuestTurnedIn and FDJ.QuestTurnedIn(q.id) or false
                local lost=FDJ.IsQuestLost and FDJ.IsQuestLost(q) or false
                local inLog=FDJ.IsQuestInLog and FDJ.IsQuestInLog(q.id) or false
                if not seen[q.id] then
                    seen[q.id]=true
                    if done then out.completed[#out.completed+1]=q.id end
                    if lost then out.lost[#out.lost+1]=q.id end
                    if inLog then out.inLog[#out.inLog+1]=q.id end
                end
                if (not FDJ.QuestMatchesFaction or FDJ.QuestMatchesFaction(q,faction)) and not q.hideFromMainList and not q.repeatable then
                    row.quests[#row.quests+1]={id=q.id,name=q.name or '?',done=not not done,lost=not not lost,inLog=not not inLog,
                        locked=out.rpg and FDJ.RPGQuestHidden and FDJ.RPGQuestHidden(name,q) or false}
                    if not lost then row.total=row.total+1; if done then row.done=row.done+1 end end
                end
            end
        end
        for _, b in ipairs(d.bosses or {}) do
            if b.name and not b.trash and not b.recipeTab then
                row.bosses[#row.bosses+1]={name=b.name,label=Label(FDJ.LocalizeBossName,b.name),npcID=b.npcID,
                    locked=FDJ.RPGBossHidden and FDJ.RPGBossHidden(name,b) or false,rare=not not b.rare}
            end
        end
        out.dungeons[#out.dungeons+1]=row
    end
    table.sort(out.completed); table.sort(out.lost); table.sort(out.inLog)
    local runs={}
    for _, r in ipairs(FDJ.RunLog and FDJ.RunLog.Runs() or {}) do runs[#runs+1]=r end
    table.sort(runs,function(a,b) if (a.created or 0)==(b.created or 0) then return (a.id or 0)>(b.id or 0) end return (a.created or 0)>(b.created or 0) end)
    for i=1,math.min(100,#runs) do out.runs[#out.runs+1]=SnapshotRun(runs[i],now) end
    return out
end
